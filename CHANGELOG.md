# 2.0.0 — 2026-10-11

- Retained all ten original role names and split read-only design/review from implementation.
- Added file ownership, IPC handoff, shared-file integration, and evidence-based completion rules.
- Corrected custom app command ACL guidance and distinction from plugin scopes.
- Replaced fixed frontend/Windows/performance prescriptions with repository-aware guidance.
- Added explicit role tools and inherited models; no provider/model/credential changes.
- Added instruction merging, known legacy migration, backup manifests, hash-checked restoration, write-failure rollback and WhatIf.
- Added native exports for current Codex, Claude Code, Cursor, OpenCode v1/v2, Gemini CLI, and current Copilot user agents.
- Added a Hermes delegate_task prompt library; it is not a native agent registry and has no independent tool sandbox.
- Added runtime detection that excludes skills-only directories and unsupported Antigravity configuration.
- Tested temporary destinations using Windows PowerShell 5.1 and PowerShell 7. Runtime loading and model behavior remain separate smoke checks.
