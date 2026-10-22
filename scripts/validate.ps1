[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'package-tools.ps1')
$packRoot = Get-PackRoot $PSScriptRoot
Assert-Pack $packRoot
Write-Host 'PASS: ten agent definitions, explicit role tools, instruction files, and PowerShell syntax.'
Write-Host 'This is package validation. It does not prove agent performance or loading inside ZCode.'
