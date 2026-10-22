[CmdletBinding(SupportsShouldProcess = $true)]
param([Parameter(Mandatory=$true)][string]$BackupPath)

. (Join-Path $PSScriptRoot 'package-tools.ps1')
$backup = Get-FullPackPath $BackupPath
Assert-NoReparsePath $backup
$manifestPath = Join-Path $backup 'manifest.json'
$manifest = [System.IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
if ($manifest.PSObject.Properties.Name -contains 'Harness') { Set-PackHarness $manifest.Harness }
else { Set-PackHarness 'zcode' }
if ($manifest.SchemaVersion -ne 1 -or $manifest.Status -notin @('Prepared','Installed','Restored')) { throw 'This backup is not a restorable installation.' }
$destination = Get-FullPackPath $manifest.DestinationRoot
$backupParent = Split-Path -Parent $backup
$expectedParent = Join-Path $destination 'backups\tauri-pack'
if ($backupParent -ine $expectedParent -or (Split-Path -Leaf $backup) -notmatch '^\d{8}-\d{6}-[a-f0-9]{8}$') { throw 'Backup location does not match its destination.' }
Assert-NoReparsePath $destination
if ($manifest.Status -eq 'Restored') {
    Write-Host 'This backup was already restored.'
    return [pscustomobject]@{ Status='AlreadyRestored'; DestinationRoot=$destination }
}
$files = @($manifest.Files)
if ($files.Count -lt 1 -or $files.Count -gt 11) { throw 'Invalid backup file count.' }
$seen = @{}
$restoreEntries = @()
foreach ($file in $files) {
    if ($seen.ContainsKey($file.RelativePath)) { throw 'Duplicate backup file entry.' }
    $seen[$file.RelativePath] = $true
    if ($file.HadOriginal -isnot [bool] -or $file.InstalledHash -notmatch '^[a-f0-9]{64}$') { throw 'Invalid backup record.' }
    $target = Get-ManagedFilePath $destination $file.RelativePath
    $saved = $null
    if ($file.HadOriginal) {
        if ($file.OriginalHash -notmatch '^[a-f0-9]{64}$') { throw 'Invalid original hash.' }
        $saved = Get-ManagedFilePath (Join-Path $backup 'saved') $file.RelativePath
        if (-not [System.IO.File]::Exists($saved) -or (Get-FileHashValue $saved) -ne $file.OriginalHash) { throw "Backup missing/corrupt: $($file.RelativePath)" }
    }
    $restoreEntries += [pscustomobject]@{ Record=$file; Target=$target; Saved=$saved }
}
if (-not $PSCmdlet.ShouldProcess($destination, 'Restore the pre-install files; refuse to overwrite later edits')) { return }
$lock = Get-PackLock $destination
try {
    # Preflight all files before mutation; a conflict leaves every destination file untouched.
    foreach ($entry in $restoreEntries) {
        $exists = [System.IO.File]::Exists($entry.Target)
        $currentHash = $null; if ($exists) { $currentHash = Get-FileHashValue $entry.Target }
        $alreadyOriginal = ($entry.Record.HadOriginal -and $currentHash -eq $entry.Record.OriginalHash) -or (-not $entry.Record.HadOriginal -and -not $exists)
        if (-not $alreadyOriginal -and $currentHash -ne $entry.Record.InstalledHash) {
            throw "Restore refused: $($entry.Record.RelativePath) was edited or removed after installation. Preserve those edits before restoring."
        }
    }
    foreach ($entry in $restoreEntries) {
        if ($entry.Record.HadOriginal) {
            Write-PackBytes $entry.Target ([System.IO.File]::ReadAllBytes($entry.Saved))
            if ((Get-FileHashValue $entry.Target) -ne $entry.Record.OriginalHash) { throw "Restore verification failed: $($entry.Record.RelativePath)" }
        } else {
            $checkedTarget = Get-ManagedFilePath $destination $entry.Record.RelativePath
            if ([System.IO.File]::Exists($checkedTarget)) { Remove-Item -LiteralPath $checkedTarget -Force }
        }
    }
    $manifest.Status = 'Restored'
    $manifest | Add-Member -NotePropertyName RestoredUtc -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
    Write-PackBytes $manifestPath ($script:Utf8.GetBytes(($manifest | ConvertTo-Json -Depth 6)))
    Write-Host "Restored previous files: $destination"
    Write-Host 'Start a NEW chat in the target program to load restored definitions.'
    [pscustomobject]@{ Status='Restored'; DestinationRoot=$destination }
} finally { $lock.Dispose() }
