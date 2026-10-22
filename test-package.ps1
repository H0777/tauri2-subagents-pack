[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'package-tools.ps1')
Assert-Pack $PSScriptRoot
$runRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('tauri-pack-check-' + [guid]::NewGuid().ToString('N'))
[System.IO.Directory]::CreateDirectory($runRoot) | Out-Null
$script:Passed = @()
function Assert-Case([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:Passed += $Name
    Write-Host "PASS: $Name"
}
function Assert-Throws([scriptblock]$Action, [string]$Name) {
    $didThrow = $false
    try { & $Action | Out-Null } catch { $didThrow = $true }
    Assert-Case $didThrow $Name
}
$install = Join-Path $PSScriptRoot 'install.ps1'
$restore = Join-Path $PSScriptRoot 'restore.ps1'

$previewRoot = Join-Path $runRoot 'preview'
& $install -DestinationRoot $previewRoot -WhatIf
Assert-Case (-not (Test-Path -LiteralPath $previewRoot)) 'WhatIf creates no destination'

foreach ($harness in @('zcode','codex','claude','cursor','opencode-v1','opencode-v2','gemini','copilot','hermes')) {
    Set-PackHarness $harness
    $destination = Join-Path $runRoot $harness
    $result = & $install -Harness $harness -DestinationRoot $destination
    Assert-Case ($result.Status -eq 'Installed' -and $result.ChangedFiles -eq 11) "$harness fresh install"
    foreach ($relative in $script:AllowedFiles) { if (-not (Test-Path -LiteralPath (Join-Path $destination $relative) -PathType Leaf)) { throw "Missing installed $relative" } }
    $again = & $install -Harness $harness -DestinationRoot $destination
    Assert-Case ($again.Status -eq 'Unchanged') "$harness idempotent reinstall"
    $restored = & $restore -BackupPath $result.BackupPath
    Assert-Case ($restored.Status -eq 'Restored') "$harness restore"
    $remaining = @($script:AllowedFiles | Where-Object { Test-Path -LiteralPath (Join-Path $destination $_) })
    Assert-Case ($remaining.Count -eq 0) "$harness restore removes only new managed files"
}

Set-PackHarness 'zcode'
$upgradeRoot = Join-Path $runRoot 'custom-upgrade'
[System.IO.Directory]::CreateDirectory((Join-Path $upgradeRoot 'agents')) | Out-Null
$originalInstructions = "# My personal rules`r`nAlways preserve Arabic text: مرحبا`r`n"
$originalPath = Join-Path $upgradeRoot 'AGENTS.md'
Write-PackBytes $originalPath ($script:Utf8.GetBytes($originalInstructions))
$originalHash = Get-FileHashValue $originalPath
$oldAgent = Join-Path $upgradeRoot 'agents\tauri-rust.md'
Write-PackBytes $oldAgent ($script:Utf8.GetBytes('my original rust agent'))
$oldAgentHash = Get-FileHashValue $oldAgent
$unrelated = Join-Path $upgradeRoot 'agents\my-other-agent.md'
Write-PackBytes $unrelated ($script:Utf8.GetBytes('unrelated'))
$unrelatedHash = Get-FileHashValue $unrelated
$upgrade = & $install -DestinationRoot $upgradeRoot
$merged = [System.IO.File]::ReadAllText($originalPath)
Assert-Case ($merged.StartsWith($originalInstructions) -and [regex]::Matches($merged, '<!-- BEGIN ZCODE-TAURI-PACK -->').Count -eq 1) 'custom instructions preserved and merged once'
$beforeConflict = Get-FileHashValue $oldAgent
[System.IO.File]::AppendAllText($originalPath, "`nLater personal edit", $script:Utf8)
Assert-Throws { & $restore -BackupPath $upgrade.BackupPath } 'restore refuses later edits'
Assert-Case ((Get-FileHashValue $oldAgent) -eq $beforeConflict) 'conflicting restore leaves other files untouched'
Write-PackBytes $originalPath ($script:Utf8.GetBytes($merged))
$restored = & $restore -BackupPath $upgrade.BackupPath
Assert-Case ((Get-FileHashValue $originalPath) -eq $originalHash -and (Get-FileHashValue $oldAgent) -eq $oldAgentHash) 'restore preserves original file bytes'
Assert-Case ((Get-FileHashValue $unrelated) -eq $unrelatedHash) 'unrelated agent survives install and restore'
$restoredAgain = & $restore -BackupPath $upgrade.BackupPath
Assert-Case ($restoredAgain.Status -eq 'AlreadyRestored') 'repeat restore is safe'

$legacyRoot = Join-Path $runRoot 'legacy'
[System.IO.Directory]::CreateDirectory($legacyRoot) | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'LEGACY-AGENTS.md') -Destination (Join-Path $legacyRoot 'AGENTS.md')
$legacyHash = Get-FileHashValue (Join-Path $legacyRoot 'AGENTS.md')
$legacyUpgrade = & $install -DestinationRoot $legacyRoot
$legacyText = [System.IO.File]::ReadAllText((Join-Path $legacyRoot 'AGENTS.md'))
Assert-Case ($legacyText.Contains('pack 2.0.0') -and -not $legacyText.Contains('ZCode / GLM')) 'exact legacy instructions upgraded without contradictory duplication'
& $restore -BackupPath $legacyUpgrade.BackupPath | Out-Null
Assert-Case ((Get-FileHashValue (Join-Path $legacyRoot 'AGENTS.md')) -eq $legacyHash) 'legacy original restored byte-for-byte'

$malformedRoot = Join-Path $runRoot 'malformed'
[System.IO.Directory]::CreateDirectory($malformedRoot) | Out-Null
Write-PackBytes (Join-Path $malformedRoot 'AGENTS.md') ($script:Utf8.GetBytes('<!-- BEGIN ZCODE-TAURI-PACK --> no end'))
Assert-Throws { & $install -DestinationRoot $malformedRoot } 'malformed markers refused before managed writes'
Assert-Case (-not (Test-Path -LiteralPath (Join-Path $malformedRoot 'agents'))) 'malformed marker failure writes no agents'

$corruptRoot = Join-Path $runRoot 'corrupt'
[System.IO.Directory]::CreateDirectory($corruptRoot) | Out-Null
Write-PackBytes (Join-Path $corruptRoot 'AGENTS.md') ($script:Utf8.GetBytes('original'))
$corruptInstall = & $install -DestinationRoot $corruptRoot
$currentHash = Get-FileHashValue (Join-Path $corruptRoot 'AGENTS.md')
Write-PackBytes (Join-Path $corruptInstall.BackupPath 'saved\AGENTS.md') ($script:Utf8.GetBytes('tampered backup'))
Assert-Throws { & $restore -BackupPath $corruptInstall.BackupPath } 'corrupt backup refused'
Assert-Case ((Get-FileHashValue (Join-Path $corruptRoot 'AGENTS.md')) -eq $currentHash) 'corrupt backup refusal leaves destination unchanged'

$interruptedRoot = Join-Path $runRoot 'interrupted'
[System.IO.Directory]::CreateDirectory($interruptedRoot) | Out-Null
Write-PackBytes (Join-Path $interruptedRoot 'AGENTS.md') ($script:Utf8.GetBytes('before interrupted install'))
$interruptedHash = Get-FileHashValue (Join-Path $interruptedRoot 'AGENTS.md')
$interruptedInstall = & $install -DestinationRoot $interruptedRoot
$interruptedManifestPath = Join-Path $interruptedInstall.BackupPath 'manifest.json'
$interruptedManifest = [IO.File]::ReadAllText($interruptedManifestPath) | ConvertFrom-Json
$interruptedManifest.Status = 'Prepared'
Write-PackBytes $interruptedManifestPath ($script:Utf8.GetBytes(($interruptedManifest | ConvertTo-Json -Depth 6)))
# Simulate a mixture of original, installed and never-written files.
Write-PackBytes (Join-Path $interruptedRoot 'AGENTS.md') ([IO.File]::ReadAllBytes((Join-Path $interruptedInstall.BackupPath 'saved\AGENTS.md')))
$neverWritten = Get-ManagedFilePath $interruptedRoot 'agents\tauri-frontend.md'
Remove-Item -LiteralPath $neverWritten
& $restore -BackupPath $interruptedInstall.BackupPath | Out-Null
Assert-Case ((Get-FileHashValue (Join-Path $interruptedRoot 'AGENTS.md')) -eq $interruptedHash -and -not (Test-Path -LiteralPath (Join-Path $interruptedRoot 'agents\tauri-rust.md'))) 'prepared backup recovers interrupted installation'

$traversalRoot = Join-Path $runRoot 'traversal'
$traversalInstall = & $install -DestinationRoot $traversalRoot
$traversalManifestPath = Join-Path $traversalInstall.BackupPath 'manifest.json'
$traversalManifest = [IO.File]::ReadAllText($traversalManifestPath) | ConvertFrom-Json
$traversalManifest.Files[0].RelativePath = '..\outside.txt'
Write-PackBytes $traversalManifestPath ($script:Utf8.GetBytes(($traversalManifest | ConvertTo-Json -Depth 6)))
$traversalBefore = Get-FileHashValue (Join-Path $traversalRoot 'AGENTS.md')
Assert-Throws { & $restore -BackupPath $traversalInstall.BackupPath } 'backup traversal record refused'
Assert-Case ((Get-FileHashValue (Join-Path $traversalRoot 'AGENTS.md')) -eq $traversalBefore) 'invalid manifest leaves managed files unchanged'

# Inject a single write failure into an isolated copy, proving automatic rollback.
$faultPack = Join-Path $runRoot 'fault-package'
[System.IO.Directory]::CreateDirectory($faultPack) | Out-Null
Get-ChildItem -LiteralPath $PSScriptRoot -Force | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $faultPack -Recurse }
$helperPath = Join-Path $faultPack 'package-tools.ps1'
$faultHelper = [System.IO.File]::ReadAllText($helperPath).Replace('function Write-PackBytes(', 'function Write-PackBytesCore(')
$faultHelper += @'

function Write-PackBytes([string]$Path, [byte[]]$Bytes) {
    if ($Path.EndsWith('agents\tauri-frontend.md')) { throw 'Injected write failure' }
    Write-PackBytesCore $Path $Bytes
}
'@
[System.IO.File]::WriteAllText($helperPath, $faultHelper, $script:Utf8)
$faultRoot = Join-Path $runRoot 'fault-destination'
[System.IO.Directory]::CreateDirectory($faultRoot) | Out-Null
Write-PackBytes (Join-Path $faultRoot 'AGENTS.md') ($script:Utf8.GetBytes('keep on rollback'))
$faultOriginalHash = Get-FileHashValue (Join-Path $faultRoot 'AGENTS.md')
Assert-Throws { & (Join-Path $faultPack 'install.ps1') -DestinationRoot $faultRoot } 'injected installation failure surfaces'
Assert-Case ((Get-FileHashValue (Join-Path $faultRoot 'AGENTS.md')) -eq $faultOriginalHash -and -not (Test-Path -LiteralPath (Join-Path $faultRoot 'agents\tauri-architect.md'))) 'failed install rolls back written files'

$autoHome = Join-Path $runRoot 'auto-home'
[System.IO.Directory]::CreateDirectory((Join-Path $autoHome '.zcode')) | Out-Null
[System.IO.Directory]::CreateDirectory((Join-Path $autoHome '.cursor\skills')) | Out-Null
Write-PackBytes (Join-Path $autoHome '.zcode\AGENTS.md') ($script:Utf8.GetBytes('personal'))
$inventory = @(& (Join-Path $PSScriptRoot 'install-all.ps1') -List -ProfileHome $autoHome)
Assert-Case (@($inventory | Where-Object Detected).Count -eq 1 -and ($inventory | Where-Object Detected).Harness -eq 'zcode') 'auto detection excludes skills-only profile'
Assert-Throws { & (Join-Path $PSScriptRoot 'install-all.ps1') -Targets opencode-v1,opencode-v2 -ProfileHome $autoHome } 'duplicate OpenCode destination refused'
& (Join-Path $PSScriptRoot 'install-all.ps1') -ProfileHome $autoHome -WhatIf
Assert-Case (-not (Test-Path -LiteralPath (Join-Path $autoHome '.zcode\agents'))) 'multi-target WhatIf creates no agents'

$report = [ordered]@{ Passed=$script:Passed.Count; Cases=$script:Passed; RunDirectory=$runRoot; PowerShell=$PSVersionTable.PSVersion.ToString(); TimestampUtc=[DateTime]::UtcNow.ToString('o') }
Write-PackBytes (Join-Path $runRoot 'results.json') ($script:Utf8.GetBytes(($report | ConvertTo-Json -Depth 4)))
Write-Host "PASS: $($script:Passed.Count) checks. Evidence retained at $runRoot"
[pscustomobject]@{ Passed=$script:Passed.Count; RunDirectory=$runRoot }
