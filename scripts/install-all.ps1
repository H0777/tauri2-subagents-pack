[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('auto','zcode','codex','claude','cursor','opencode-v1','opencode-v2','gemini','copilot','hermes')][string[]]$Targets = @('auto'),
    [switch]$List,
    [string]$ProfileHome = ([Environment]::GetFolderPath('UserProfile')),
    [ValidateSet('v1','v2')][string]$OpenCodeVersion = 'v1'
)
. (Join-Path $PSScriptRoot 'package-tools.ps1')
$packRoot = Get-PackRoot $PSScriptRoot
Assert-Pack $packRoot
$realProfile = ([Environment]::GetFolderPath('UserProfile'))
$useEnvironment = (Get-FullPackPath $ProfileHome) -ieq (Get-FullPackPath $realProfile)
$nativeTargets = @('zcode','codex','claude','cursor',('opencode-' + $OpenCodeVersion),'gemini','copilot','hermes')
$inventory = @()
foreach ($harness in $nativeTargets) {
    $root = Get-HarnessDefaultRoot $harness $ProfileHome $useEnvironment
    $cliName = $harness; if ($harness -like 'opencode-*') { $cliName = 'opencode' }
    $command = $null; if ($useEnvironment) { $command = Get-Command $cliName -ErrorAction SilentlyContinue | Select-Object -First 1 }
    $evidence = @(); if ($command) { $evidence += 'CLI on PATH' }
    $signalFiles = switch ($harness) {
        'zcode' { @('AGENTS.md') }
        'codex' { @('config.toml') }
        'claude' { @('settings.json','CLAUDE.md') }
        'cursor' { @('mcp.json') }
        { $_ -like 'opencode-*' } { @('opencode.json','opencode.jsonc') }
        'gemini' { @('settings.json','GEMINI.md') }
        'copilot' { @('config.json') }
        'hermes' { @('config.yaml') }
    }
    foreach ($signal in $signalFiles) { if (Test-Path -LiteralPath (Join-Path $root $signal) -PathType Leaf) { $evidence += "profile $signal" } }
    $agentDirectory = Join-Path $root 'agents'
    if ((Test-Path -LiteralPath $agentDirectory) -and @(Get-ChildItem -LiteralPath $agentDirectory -File -ErrorAction SilentlyContinue).Count -gt 0) { $evidence += 'existing agent definitions' }
    if ($useEnvironment) {
        $appRelative = switch ($harness) {
            'zcode' { 'Programs\ZCode\ZCode.exe' }
            'cursor' { 'Programs\cursor\Cursor.exe' }
            'codex' { 'OpenAI\Codex' }
            default { $null }
        }
        if ($appRelative -and (Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA $appRelative))) { $evidence += 'desktop installation' }
        if ($harness -eq 'copilot') {
            $extensionRoot = Join-Path $ProfileHome '.vscode\extensions'
            if ((Test-Path -LiteralPath $extensionRoot) -and @(Get-ChildItem -LiteralPath $extensionRoot -Directory -Filter 'github.copilot*' -ErrorAction SilentlyContinue).Count -gt 0) { $evidence += 'VS Code Copilot extension' }
        }
    }
    $detected = $evidence.Count -gt 0
    $kind = 'Native'; if ($harness -eq 'hermes') { $kind = 'Delegation bridge' }
    $note = $evidence -join ', '
    if (-not $detected) {
        $note = 'Not detected'
        if (Test-Path -LiteralPath $root) { $note = 'Profile folder only; not enough evidence to auto-install' }
    }
    $inventory += [pscustomobject]@{ Harness=$harness; Detected=$detected; Kind=$kind; Destination=$root; Evidence=$note }
}
if ($List) {
    $inventory
    if (Test-Path -LiteralPath (Join-Path $ProfileHome '.gemini\antigravity')) { Write-Host 'Antigravity detected: no verified adapter; no files will be installed there.' }
    return
}
if ($Targets -contains 'auto') {
    if ($Targets.Count -ne 1) { throw 'Use auto by itself or specify target names.' }
    $selected = @($inventory | Where-Object Detected)
} else {
    $selected = @()
    foreach ($harness in @($Targets | Select-Object -Unique)) {
        $selected += [pscustomobject]@{ Harness=$harness; Destination=(Get-HarnessDefaultRoot $harness $ProfileHome $useEnvironment) }
    }
}
$allRoots = @{}
foreach ($item in $selected) {
    $fullRoot = Get-FullPackPath $item.Destination
    if ($allRoots.ContainsKey($fullRoot)) { throw 'Two selected adapters share the same destination. Choose one OpenCode version.' }
    $allRoots[$fullRoot] = $true
}
if ($selected.Count -eq 0) { Write-Host 'No supported runtime detected. Use -List or specify -Targets explicitly.'; return }
$failures = @()
foreach ($item in $selected) {
    if ($PSCmdlet.ShouldProcess($item.Destination, "Install Tauri pack for $($item.Harness), with backup")) {
        try { & (Join-Path $PSScriptRoot 'install.ps1') -Harness $item.Harness -DestinationRoot $item.Destination -Confirm:$false }
        catch { $failures += "$($item.Harness): $($_.Exception.Message)"; Write-Warning $failures[-1] }
    }
}
if ($failures.Count -gt 0) { throw ('Some targets failed. Successful targets retain their backups. ' + ($failures -join ' | ')) }
