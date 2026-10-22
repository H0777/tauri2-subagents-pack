#!/usr/bin/env bash
# ==============================================================================
# Tauri 2 Subagents Pack - Root Launcher (macOS / Linux)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/scripts/install.sh" "$@"
