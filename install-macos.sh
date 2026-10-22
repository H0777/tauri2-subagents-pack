#!/usr/bin/env bash
# ==============================================================================
# Tauri 2 Subagents Pack - macOS Installer
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "[WARNING] This script is optimized for macOS. Detected: $(uname -s)"
fi

echo "Starting macOS installation..."
bash "$SCRIPT_DIR/install.sh" "$@"
