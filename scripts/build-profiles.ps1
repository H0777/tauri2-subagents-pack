[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'package-tools.ps1')
$packRoot = Get-PackRoot $PSScriptRoot
Assert-Pack $packRoot
$common = [System.IO.File]::ReadAllText((Join-Path $packRoot 'AGENTS.md')).Replace('ZCode','the agent runtime')
$readOnly = @('tauri-architect','tauri-ipc','tauri-security')
foreach ($harness in @('codex','claude','cursor','opencode-v1','opencode-v2','gemini','copilot','hermes')) {
    Set-PackHarness $harness
    $exportRoot = Join-Path $packRoot ('profiles\' + $harness)
    [System.IO.Directory]::CreateDirectory((Join-Path $exportRoot 'agents')) | Out-Null
    $guide = $common
    if ($harness -in @('hermes','cursor','copilot')) {
        $guide = "# Explicit activation`nRead this guide in the parent chat before requesting Tauri delegation; this file is not assumed to be auto-loaded by the runtime.`n`n" + $common
    }
    if ($harness -eq 'hermes') {
        $guide += "`n## Hermes delegation bridge`nThis is a role-prompt library, not native named subagent registration. Read the selected tauri-pack/roles/<name>.md and pass its complete text, the objective, writable files and acceptance criteria as delegate_task context. Pass a concise goal. Use the documented goal/context or tasks arguments; do not invent an agent_type or per-task model option. Children inherit parent toolsets: read-only restrictions here are instructions, not a tool sandbox. Set actual tool policies in Hermes separately when strict enforcement is required. This pack does not change config.yaml, delegation limits, provider or model.`n"
    }
    Write-PackBytes (Join-Path $exportRoot $script:InstructionFile) ($script:Utf8.GetBytes($guide))
    foreach ($name in $script:AgentNames) {
        $source = [System.IO.File]::ReadAllText((Join-Path $packRoot ('agents\' + $name + '.md')))
        $match = [regex]::Match($source, '\A---\r?\n(.*?)\r?\n---\r?\n(.+)\z', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $header = $match.Groups[1].Value
        $description = ([regex]::Match($header, '(?m)^description: (.+)$')).Groups[1].Value
        $tools = ([regex]::Match($header, '(?m)^tools: (.+)$')).Groups[1].Value
        $turns = ([regex]::Match($header, '(?m)^maxTurns: (.+)$')).Groups[1].Value
        $body = $match.Groups[2].Value.Replace('ZCode', 'your agent runtime')
        # Embed shared rules so roles do not depend on a runtime's instruction injection behavior.
        $body = $body.Trim() + "`n`n" + $common.Trim() + "`n"
        $isReadOnly = $readOnly -contains $name
        $extension = '.md'
        switch ($harness) {
            'codex' {
                $extension = '.toml'
                $sandbox = ''; if ($isReadOnly) { $sandbox = "sandbox_mode = `"read-only`"`n" }
                # Literal multiline TOML avoids escaping Rust examples and Windows paths.
                if ($body.Contains("'''")) { throw 'Prompt cannot contain the TOML literal delimiter.' }
                $output = "name = `"$name`"`ndescription = $description`n${sandbox}developer_instructions = '''`n$body'''`n"
            }
            'claude' {
                $output = "---`nname: $name`ndescription: $description`nmodel: inherit`ntools: $tools`nmaxTurns: $turns`n---`n$body"
            }
            'cursor' {
                $readonlyValue = $isReadOnly.ToString().ToLowerInvariant()
                $output = "---`nname: $name`ndescription: $description`nmodel: inherit`nreadonly: $readonlyValue`n---`n$body"
            }
            'opencode-v1' {
                $permissions = "permission:`n  task: deny"
                if ($isReadOnly) { $permissions += "`n  edit: deny`n  bash: deny" }
                $output = "---`ndescription: $description`nmode: subagent`n$permissions`n---`n$body"
            }
            'opencode-v2' {
                $permissions = "permissions:`n  - action: subagent`n    resource: '*'`n    effect: deny"
                if ($isReadOnly) { $permissions += "`n  - action: edit`n    resource: '*'`n    effect: deny`n  - action: shell`n    resource: '*'`n    effect: deny" }
                $output = "---`ndescription: $description`nmode: subagent`nsteps: $turns`n$permissions`n---`n$body"
            }
            'gemini' {
                $geminiTools = 'tools: [read_file, list_directory, glob, grep_search, web_fetch, google_web_search]'
                if (-not $isReadOnly) { $geminiTools = 'tools: [read_file, list_directory, glob, grep_search, web_fetch, google_web_search, run_shell_command, replace, write_file]' }
                $output = "---`nname: $name`ndescription: $description`nkind: local`nmodel: inherit`nmax_turns: $turns`n$geminiTools`n---`n$body"
            }
            'copilot' {
                $extension = '.agent.md'
                $copilotTools = "tools: ['read', 'search', 'web']"
                if (-not $isReadOnly) { $copilotTools = "tools: ['read', 'search', 'web', 'edit', 'execute']" }
                $output = "---`nname: $name`ndescription: $description`nuser-invocable: true`ndisable-model-invocation: false`nagents: []`n$copilotTools`n---`n$body"
            }
            'hermes' { $output = "# $name $([char]0x2014) delegated role prompt`n`n$body" }
        }
        $agentDirectory = 'agents'; if ($harness -eq 'hermes') { $agentDirectory = 'tauri-pack\roles' }
        Write-PackBytes (Join-Path $exportRoot ($agentDirectory + '\' + $name + $extension)) ($script:Utf8.GetBytes($output))
    }
}
Set-PackHarness 'zcode'
Write-Host 'Built seven native harness exports and a Hermes delegation bridge from the canonical prompts.'
