# Shared by installation, restoration and validation. Windows PowerShell 5.1+.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:PackVersion = '2.0.0'
$script:AgentNames = @('tauri-architect','tauri-frontend','tauri-ipc','tauri-perf','tauri-plugins','tauri-release','tauri-rust','tauri-security','tauri-test','tauri-windows')
$script:AllowedFiles = @('AGENTS.md') + @($script:AgentNames | ForEach-Object { 'agents\' + $_ + '.md' })
$script:Utf8 = New-Object System.Text.UTF8Encoding($false)

function Set-PackHarness([string]$Harness) {
    $instruction = 'AGENTS.md'; $extension = '.md'; $agentDirectory = 'agents'
    switch ($Harness) {
        'zcode' { }
        'codex' { $extension = '.toml' }
        'claude' { $instruction = 'CLAUDE.md' }
        'cursor' { $instruction = 'tauri-pack-guide.md' }
        'opencode-v1' { }
        'opencode-v2' { }
        'gemini' { $instruction = 'GEMINI.md' }
        'copilot' { $instruction = 'tauri-pack-guide.md'; $extension = '.agent.md' }
        'hermes' { $instruction = 'tauri-pack-guide.md'; $agentDirectory = 'tauri-pack\roles' }
        default { throw "Unsupported native harness: $Harness" }
    }
    $script:InstructionFile = $instruction
    $script:AllowedFiles = @($instruction) + @($script:AgentNames | ForEach-Object { $agentDirectory + '\' + $_ + $extension })
}

function Get-HarnessDefaultRoot([string]$Harness, [string]$ProfileHome, [bool]$UseEnvironment = $true) {
    switch ($Harness) {
        'zcode' { return Join-Path $ProfileHome '.zcode' }
        'codex' {
            if ($UseEnvironment -and $env:CODEX_HOME) { return $env:CODEX_HOME }
            return Join-Path $ProfileHome '.codex'
        }
        'claude' {
            if ($UseEnvironment -and $env:CLAUDE_CONFIG_DIR) { return $env:CLAUDE_CONFIG_DIR }
            return Join-Path $ProfileHome '.claude'
        }
        'cursor' { return Join-Path $ProfileHome '.cursor' }
        { $_ -in @('opencode-v1','opencode-v2') } {
            if ($UseEnvironment -and $env:XDG_CONFIG_HOME) { return Join-Path $env:XDG_CONFIG_HOME 'opencode' }
            return Join-Path $ProfileHome '.config\opencode'
        }
        'gemini' { return Join-Path $ProfileHome '.gemini' }
        'copilot' { return Join-Path $ProfileHome '.copilot' }
        'hermes' {
            if ($UseEnvironment -and $env:HERMES_HOME) { return $env:HERMES_HOME }
            return Join-Path $ProfileHome '.hermes'
        }
        default { throw "Unsupported native harness: $Harness" }
    }
}

Set-PackHarness 'zcode'

function Get-FullPackPath([string]$Path) {
    [System.IO.Path]::GetFullPath($Path).TrimEnd([char[]]@('\','/'))
}

function Assert-NoReparsePath([string]$Path) {
    $cursor = [System.IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Refusing a junction/symlink path: $cursor"
            }
        }
        $parent = Split-Path -Parent $cursor
        if ($parent -eq $cursor) { break }
        $cursor = $parent
    }
}

function Get-ManagedFilePath([string]$Root, [string]$RelativePath) {
    if ($script:AllowedFiles -cnotcontains $RelativePath) { throw "Unrecognized managed file: $RelativePath" }
    $fullRoot = Get-FullPackPath $Root
    $target = [System.IO.Path]::GetFullPath((Join-Path $fullRoot $RelativePath))
    if (-not $target.StartsWith($fullRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes destination: $target"
    }
    Assert-NoReparsePath $target
    if ((Test-Path -LiteralPath $target) -and (Get-Item -LiteralPath $target).PSIsContainer) { throw "Expected file: $target" }
    $target
}

function Get-BytesHash([byte[]]$Bytes) {
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    try { ([System.BitConverter]::ToString($hasher.ComputeHash($Bytes))).Replace('-','').ToLowerInvariant() }
    finally { $hasher.Dispose() }
}

function Get-FileHashValue([string]$Path) {
    Get-BytesHash ([System.IO.File]::ReadAllBytes($Path))
}

function Write-PackBytes([string]$Path, [byte[]]$Bytes) {
    Assert-NoReparsePath $Path
    $parent = Split-Path -Parent $Path
    [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    $temporary = Join-Path $parent ('.tauri-pack-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [System.IO.File]::WriteAllBytes($temporary, $Bytes)
        if ([System.IO.File]::Exists($Path)) { [System.IO.File]::Replace($temporary, $Path, [NullString]::Value) }
        else { [System.IO.File]::Move($temporary, $Path) }
    } finally {
        if ([System.IO.File]::Exists($temporary)) { [System.IO.File]::Delete($temporary) }
    }
}

function Get-PackLock([string]$Root) {
    $lockPath = Join-Path $Root '.tauri-pack.lock'
    Assert-NoReparsePath $lockPath
    [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
}

function Get-MergedInstructions([string]$Existing, [string]$Instructions, [string]$Legacy) {
    $begin = '<!-- BEGIN ZCODE-TAURI-PACK -->'
    $end = '<!-- END ZCODE-TAURI-PACK -->'
    $block = $begin + "`r`n" + $Instructions.Trim() + "`r`n" + $end
    $beginCount = [regex]::Matches($Existing, [regex]::Escape($begin)).Count
    $endCount = [regex]::Matches($Existing, [regex]::Escape($end)).Count
    if ($beginCount -ne $endCount -or $beginCount -gt 1) { throw 'AGENTS.md contains malformed/duplicate pack markers. No instructions were changed.' }
    if ($beginCount -eq 1) {
        $pattern = '(?s)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end)
        if (-not [regex]::IsMatch($Existing, $pattern)) { throw 'Pack markers are out of order.' }
        $match = [regex]::Match($Existing, $pattern)
        return $Existing.Substring(0, $match.Index) + $block + $Existing.Substring($match.Index + $match.Length)
    }
    $normalizedExisting = $Existing.Replace("`r`n", "`n").Trim()
    $normalizedLegacy = $Legacy.Replace("`r`n", "`n").Trim()
    if ($normalizedExisting.Length -eq 0 -or $normalizedExisting -ceq $normalizedLegacy) { return $block + "`r`n" }
    return $Existing + "`r`n`r`n" + $block + "`r`n"
}

function Get-PackRoot([string]$StartPath) {
    if (-not $StartPath) { $StartPath = $PSScriptRoot }
    $curr = [System.IO.Path]::GetFullPath($StartPath)
    if (Test-Path -LiteralPath (Join-Path $curr 'agents')) { return $curr }
    $parent = Split-Path -Parent $curr
    if (Test-Path -LiteralPath (Join-Path $parent 'agents')) { return $parent }
    return $curr
}

function Assert-Pack([string]$Root) {
    $packRoot = Get-PackRoot $Root
    $allowedKeys = @('name','description','color','model','tools','injectAgentsMd','maxTurns')
    $readOnly = @('tauri-architect','tauri-ipc','tauri-security')
    $validTools = @('Read','Grep','Glob','Bash','Edit','Write','WebFetch','WebSearch','TodoWrite')
    $agentFiles = @(Get-ChildItem -LiteralPath (Join-Path $packRoot 'agents') -Filter '*.md' -File)
    if ($agentFiles.Count -ne 10) { throw 'The package must contain exactly ten agent files.' }
    foreach ($name in $script:AgentNames) {
        $path = Join-Path $packRoot ('agents\' + $name + '.md')
        $content = [System.IO.File]::ReadAllText($path)
        $match = [regex]::Match($content, '\A---\r?\n(.*?)\r?\n---\r?\n(.+)\z', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if (-not $match.Success) { throw "Invalid frontmatter/body: $name" }
        $fields = @{}
        foreach ($line in ($match.Groups[1].Value -split '\r?\n')) {
            if ($line -notmatch '^([A-Za-z]+): (.+)$') { throw "Invalid frontmatter line in ${name}: $line" }
            $key = $Matches[1]; $value = $Matches[2]
            if ($allowedKeys -cnotcontains $key -or $fields.ContainsKey($key)) { throw "Unknown/duplicate key in ${name}: $key" }
            $fields[$key] = $value
        }
        foreach ($key in $allowedKeys) { if (-not $fields.ContainsKey($key)) { throw "Missing $key in $name" } }
        if ($fields.name -cne $name -or $fields.model -cne 'inherit' -or $fields.injectAgentsMd -cne 'true') { throw "Invalid identity/inheritance: $name" }
        if ($fields.description -notmatch '^"Use [^"\r\n]+"$' -or $fields.description.Length -gt 1024) { throw "Invalid description: $name" }
        if ($fields.maxTurns -notmatch '^\d+$' -or [int]$fields.maxTurns -lt 8 -or [int]$fields.maxTurns -gt 32) { throw "Invalid turn budget: $name" }
        if (@('blue','pink','purple','magenta','green','gray','orange','red','yellow','cyan') -cnotcontains $fields.color) { throw "Invalid color: $name" }
        $agentTools = @($fields.tools -split ',\s*')
        foreach ($tool in $agentTools) { if ($validTools -cnotcontains $tool) { throw "Unknown tool $tool in $name" } }
        if ($readOnly -contains $name) {
            foreach ($tool in @('Bash','Edit','Write','TodoWrite')) { if ($agentTools -contains $tool) { throw "Read-only role has writable tool: $name" } }
        } else {
            foreach ($tool in @('Bash','Edit','Write')) { if ($agentTools -notcontains $tool) { throw "Implementation role missing $tool : $name" } }
        }
        if ($match.Groups[2].Value -notmatch '(?i)do not.*launch subagents|do not.*launch other subagents') { throw "Missing child delegation boundary: $name" }
    }
    $docDir = if (Test-Path (Join-Path $packRoot 'docs')) { Join-Path $packRoot 'docs' } else { $packRoot }
    $scriptDir = if (Test-Path (Join-Path $packRoot 'scripts')) { Join-Path $packRoot 'scripts' } else { $packRoot }
    if (-not (Test-Path -LiteralPath (Join-Path $packRoot 'AGENTS.md') -PathType Leaf)) { throw "Missing package file: AGENTS.md" }
    if (-not (Test-Path -LiteralPath (Join-Path $packRoot 'README.md') -PathType Leaf)) { throw "Missing package file: README.md" }
    foreach ($file in @('LEGACY-AGENTS.md','INSTALL.txt','SMOKE-TESTS.md')) {
        $found = (Test-Path -LiteralPath (Join-Path $docDir $file) -PathType Leaf) -or (Test-Path -LiteralPath (Join-Path $packRoot $file) -PathType Leaf)
        if (-not $found) { throw "Missing package file: $file" }
    }
    foreach ($file in @('install.ps1','restore.ps1','validate.ps1','package-tools.ps1')) {
        $found = (Test-Path -LiteralPath (Join-Path $scriptDir $file) -PathType Leaf) -or (Test-Path -LiteralPath (Join-Path $packRoot $file) -PathType Leaf)
        if (-not $found) { throw "Missing package file: $file" }
    }
    $ps1Files = @(Get-ChildItem -LiteralPath $packRoot -Filter '*.ps1' -File) + @(Get-ChildItem -LiteralPath $scriptDir -Filter '*.ps1' -File) | Select-Object -Unique
    foreach ($path in $ps1Files) {
        $tokens = $null; $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($path.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
        if ($parseErrors.Count -gt 0) { throw "PowerShell parse error in $($path.Name): $($parseErrors[0].Message)" }
    }
}
