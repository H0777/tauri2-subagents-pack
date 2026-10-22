"""Optional author check: Python 3.11+ and PyYAML; not needed for installation."""
from pathlib import Path
import json
import tomllib
import yaml

root = Path(__file__).resolve().parent
names = {p.stem for p in (root / "agents").glob("*.md")}
readonly = {"tauri-architect", "tauri-ipc", "tauri-security"}
results = []

def parse_md(path):
    text = path.read_text(encoding="utf-8-sig")
    assert text.startswith("---\n"), path
    header, body = text[4:].split("\n---\n", 1)
    fields = yaml.safe_load(header)
    assert isinstance(fields, dict) and body.strip(), path
    assert isinstance(fields.get("description"), str), path
    return fields, body

for path in sorted((root / "agents").glob("*.md")):
    fields, body = parse_md(path)
    assert fields["name"] == path.stem and fields["model"] == "inherit"
    assert fields["injectAgentsMd"] is True and isinstance(fields["maxTurns"], int)
    tools = {s.strip() for s in fields["tools"].split(",")}
    if path.stem in readonly:
        assert not tools.intersection({"Bash", "Edit", "Write"}), path
    else:
        assert {"Bash", "Edit", "Write"} <= tools, path
    results.append(str(path.relative_to(root)))

for directory in sorted((root / "profiles").iterdir()):
    harness = directory.name
    if harness == "hermes":
        paths = sorted((directory / "tauri-pack" / "roles").glob("*.md"))
        assert {p.stem for p in paths} == names
        for path in paths:
            assert "delegated role prompt" in path.read_text(encoding="utf-8")
            results.append(str(path.relative_to(root)))
        continue
    paths = sorted((directory / "agents").iterdir())
    assert len(paths) == 10, harness
    for path in paths:
        name = path.name.removesuffix(".agent.md").removesuffix(".md").removesuffix(".toml")
        assert name in names, path
        if harness == "codex":
            fields = tomllib.loads(path.read_text(encoding="utf-8"))
            assert fields["name"] == name and isinstance(fields["description"], str)
            assert fields["developer_instructions"].strip()
            assert "model" not in fields and "model_reasoning_effort" not in fields
            if name in readonly:
                assert fields["sandbox_mode"] == "read-only", path
        else:
            fields, body = parse_md(path)
            assert "injectAgentsMd" not in fields, path
            if harness == "claude":
                assert fields["name"] == name and isinstance(fields["tools"], str)
            elif harness == "cursor":
                assert fields["readonly"] == (name in readonly), path
                assert set(fields) == {"name", "description", "model", "readonly"}
            elif harness == "gemini":
                assert fields["kind"] == "local" and isinstance(fields["tools"], list)
                assert isinstance(fields["max_turns"], int)
                if name in readonly:
                    assert not set(fields["tools"]).intersection({"run_shell_command", "replace", "write_file"})
            elif harness == "copilot":
                assert fields["agents"] == [] and fields["disable-model-invocation"] is False
                assert isinstance(fields["tools"], list)
                if name in readonly:
                    assert not set(fields["tools"]).intersection({"edit", "execute"})
            elif harness == "opencode-v1":
                assert fields["mode"] == "subagent" and fields["permission"]["task"] == "deny"
                assert "permissions" not in fields
                if name in readonly:
                    assert fields["permission"]["edit"] == fields["permission"]["bash"] == "deny"
            elif harness == "opencode-v2":
                assert fields["mode"] == "subagent" and isinstance(fields["permissions"], list)
                assert "permission" not in fields
                denied = {r["action"] for r in fields["permissions"] if r["effect"] == "deny"}
                assert "subagent" in denied
                if name in readonly:
                    assert {"edit", "shell"} <= denied
            else:
                raise AssertionError(f"Unknown export: {harness}")
        results.append(str(path.relative_to(root)))

print(json.dumps({"validated_definitions": len(results), "formats": "YAML and TOML plus Hermes prompt library", "files": results}, ensure_ascii=False, indent=2))
