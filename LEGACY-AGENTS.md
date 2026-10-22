# Tauri 2 + Rust (Windows 11) — ZCode / GLM

## Architecture
- Tauri 2. Capabilities, not v1 allowlists.
- Webview = UI. Rust = FS, DB, license, OS, network secrets.
- `#[tauri::command]` + `invoke`. Events one-way. Channels for streams.
- Match the existing frontend. Do not add a new UI framework.

## Windows 11
- Target `x86_64-pc-windows-msvc`
- AppData under %LOCALAPPDATA%, never write into Program Files at runtime
- WebView2 is built into Win11
- Paths: PathBuf, not POSIX

## Security
- Minimum capabilities. Scope fs to app data.
- CSP on. No unbounded shell.
- License/activation in Rust only
- No secrets in the frontend or in logs

## Quality
- thiserror + Result on commands, no unwrap
- After Rust edits: cargo check / cargo test in src-tauri
- Do not expand scope

## Delegate
- Structure: @tauri-architect
- Commands/state: @tauri-rust
- UI invoke: @tauri-frontend
- IPC shape: @tauri-ipc
- Plugins/permissions: @tauri-plugins
- Win11 OS behavior: @tauri-windows
- Tests: @tauri-test
- Jank/size: @tauri-perf
- Threats: @tauri-security
- NSIS/MSI/sign: @tauri-release
