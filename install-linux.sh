#!/usr/bin/env bash
# ==============================================================================
# Tauri 2 Subagents Pack - Linux Installer
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(uname -s)" != "Linux" ]; then
    echo "[WARNING] This script is optimized for Linux. Detected: $(uname -s)"
fi

echo "Starting Linux installation..."
bash "$SCRIPT_DIR/install.sh" "$@"
