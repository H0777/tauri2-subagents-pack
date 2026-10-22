[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('zcode','codex','claude','cursor','opencode-v1','opencode-v2','gemini','copilot','hermes')][string]$Harness = 'zcode',
    [string]$DestinationRoot
)

. (Join-Path $PSScriptRoot 'package-tools.ps1')
Assert-Pack $PSScriptRoot
Set-PackHarness $Harness
if (-not $DestinationRoot) { $DestinationRoot = Get-HarnessDefaultRoot $Harness ([Environment]::GetFolderPath('UserProfile')) }
$sourceRoot = $PSScriptRoot
if ($Harness -ne 'zcode') { $sourceRoot = Join-Path $PSScriptRoot ('profiles\' + $Harness) }
foreach ($relative in $script:AllowedFiles) {
    if (-not [System.IO.File]::Exists((Join-Path $sourceRoot $relative))) { throw "Missing $Harness export: $relative. Run build-profiles.ps1." }
}
$destination = Get-FullPackPath $DestinationRoot
Assert-NoReparsePath $destination
if (-not $PSCmdlet.ShouldProcess($destination, 'Install ten Tauri agents and merge managed instructions; back up changed files')) { return }
[System.IO.Directory]::CreateDirectory($destination) | Out-Null
$lock = Get-PackLock $destination
try {
    $planned = @()
    foreach ($relative in $script:AllowedFiles) {
        $target = Get-ManagedFilePath $destination $relative
        $hadOriginal = [System.IO.File]::Exists($target)
        if ($relative -eq $script:InstructionFile) {
            $existing = ''; if ($hadOriginal) { $existing = [System.IO.File]::ReadAllText($target) }
            $legacy = ''; if ($Harness -eq 'zcode') { $legacy = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'LEGACY-AGENTS.md')) }
            $merged = Get-MergedInstructions $existing ([System.IO.File]::ReadAllText((Join-Path $sourceRoot $script:InstructionFile))) $legacy
            $bytes = $script:Utf8.GetBytes($merged)
        } else { $bytes = [System.IO.File]::ReadAllBytes((Join-Path $sourceRoot $relative)) }
        $newHash = Get-BytesHash $bytes
        $oldHash = $null; if ($hadOriginal) { $oldHash = Get-FileHashValue $target }
        if ($oldHash -ne $newHash) {
            $planned += [pscustomobject]@{ RelativePath=$relative; Target=$target; Bytes=$bytes; HadOriginal=$hadOriginal; OriginalHash=$oldHash; InstalledHash=$newHash }
        }
    }
    if ($planned.Count -eq 0) {
        Write-Host 'Pack 2.0.0 is already installed with identical content. No files changed.'
        return [pscustomobject]@{ Status='Unchanged'; DestinationRoot=$destination; BackupPath=$null; ChangedFiles=0 }
    }
    $backupId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
    $backupPath = Join-Path $destination ('backups\tauri-pack\' + $backupId)
    Assert-NoReparsePath $backupPath
    [System.IO.Directory]::CreateDirectory($backupPath) | Out-Null
    $records = @()
    foreach ($entry in $planned) {
        if ($entry.HadOriginal) {
            $saved = Get-ManagedFilePath (Join-Path $backupPath 'saved') $entry.RelativePath
            [System.IO.Directory]::CreateDirectory((Split-Path -Parent $saved)) | Out-Null
            [System.IO.File]::Copy($entry.Target, $saved, $false)
            if ((Get-FileHashValue $saved) -ne $entry.OriginalHash) { throw "Original changed during backup: $($entry.RelativePath). Installation stopped before writing." }
        }
        $records += [pscustomobject]@{ RelativePath=$entry.RelativePath; HadOriginal=$entry.HadOriginal; OriginalHash=$entry.OriginalHash; InstalledHash=$entry.InstalledHash }
    }
    $manifestPath = Join-Path $backupPath 'manifest.json'
    $manifest = [ordered]@{ SchemaVersion=1; PackVersion=$script:PackVersion; Harness=$Harness; DestinationRoot=$destination; CreatedUtc=[DateTime]::UtcNow.ToString('o'); Status='Prepared'; Files=@($records) }
    Write-PackBytes $manifestPath ($script:Utf8.GetBytes(($manifest | ConvertTo-Json -Depth 6)))
    # Check every original again before the first write. The lock also excludes another installer/restore.
    foreach ($entry in $planned) {
        if ($entry.HadOriginal) {
            if (-not [System.IO.File]::Exists($entry.Target) -or (Get-FileHashValue $entry.Target) -ne $entry.OriginalHash) { throw "Destination changed during preparation: $($entry.RelativePath)" }
        } elseif ([System.IO.File]::Exists($entry.Target)) { throw "Destination appeared during preparation: $($entry.RelativePath)" }
    }
    $written = @()
    try {
        foreach ($entry in $planned) {
            Write-PackBytes $entry.Target $entry.Bytes
            $written += $entry
            if ((Get-FileHashValue $entry.Target) -ne $entry.InstalledHash) { throw "Verification failed: $($entry.RelativePath)" }
        }
        $manifest.Status = 'Installed'
        Write-PackBytes $manifestPath ($script:Utf8.GetBytes(($manifest | ConvertTo-Json -Depth 6)))
    } catch {
        $installFailure = $_
        foreach ($entry in $written) {
            if ($entry.HadOriginal) {
                $saved = Get-ManagedFilePath (Join-Path $backupPath 'saved') $entry.RelativePath
                Write-PackBytes $entry.Target ([System.IO.File]::ReadAllBytes($saved))
            } else {
                $checkedTarget = Get-ManagedFilePath $destination $entry.RelativePath
                if ([System.IO.File]::Exists($checkedTarget)) { Remove-Item -LiteralPath $checkedTarget -Force }
            }
        }
        $manifest.Status = 'RolledBack'
        Write-PackBytes $manifestPath ($script:Utf8.GetBytes(($manifest | ConvertTo-Json -Depth 6)))
        throw $installFailure
    }
    Write-Host "Installed pack 2.0.0 ($Harness): $destination"
    Write-Host "Backup: $backupPath"
    Write-Host 'Start a NEW chat and check the ten tauri-* roles. Read MULTI-HARNESS.md for runtime-specific steps.'
    if ($Harness -eq 'hermes') { Write-Host 'Hermes export is a role-prompt library for delegate_task, not a native named-agent registry. Load tauri-pack-guide.md explicitly.' }
    [pscustomobject]@{ Status='Installed'; Harness=$Harness; DestinationRoot=$destination; BackupPath=$backupPath; ChangedFiles=$planned.Count }
} finally { $lock.Dispose() }
