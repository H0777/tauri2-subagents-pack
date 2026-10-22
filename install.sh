#!/usr/bin/env bash
# ==============================================================================
# Tauri 2 Subagents Pack - Cross-Platform Installer (macOS / Linux)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_VERSION="2.0.0"

# Colors for terminal output
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

OS_TYPE="$(uname -s)"
case "$OS_TYPE" in
    Darwin) OS_NAME="macOS" ;;
    Linux)  OS_NAME="Linux" ;;
    *)      OS_NAME="$OS_TYPE" ;;
esac

echo -e "${BOLD}${CYAN}=== Tauri 2 Subagents Pack v${PACK_VERSION} Installer ===${RESET}"
echo -e "Operating System detected: ${BOLD}${GREEN}${OS_NAME}${RESET}\n"

# ------------------------------------------------------------------------------
# Helper: SHA256 checksum
# ------------------------------------------------------------------------------
calc_sha256() {
    local file="$1"
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
    else
        openssl dgst -sha256 "$file" | awk '{print $NF}'
    fi
}

# ------------------------------------------------------------------------------
# Helper: Instruction File Merge
# ------------------------------------------------------------------------------
merge_instructions() {
    local target_file="$1"
    local pack_file="$2"
    local begin_marker="<!-- BEGIN ZCODE-TAURI-PACK -->"
    local end_marker="<!-- END ZCODE-TAURI-PACK -->"

    local pack_content
    pack_content="$(cat "$pack_file")"
    local block="${begin_marker}\n${pack_content}\n${end_marker}"

    if [ ! -f "$target_file" ]; then
        echo -e "${block}" > "$target_file"
        return
    fi

    local target_content
    target_content="$(cat "$target_file")"

    if echo "$target_content" | grep -Fq "$begin_marker"; then
        # Replace existing marked block
        python3 -c "
import sys, re
begin = '''$begin_marker'''
end = '''$end_marker'''
target = open('$target_file', 'r', encoding='utf-8', errors='ignore').read()
replacement = open('$pack_file', 'r', encoding='utf-8').read()
block = f'{begin}\n{replacement.strip()}\n{end}'
pattern = re.escape(begin) + '.*?' + re.escape(end)
new_content = re.sub(pattern, block, target, flags=re.DOTALL)
open('$target_file', 'w', encoding='utf-8').write(new_content)
" 2>/dev/null || {
            # Fallback if Python is not present
            sed -i.bak "/${begin_marker}/,/${end_marker}/d" "$target_file"
            echo -e "\n${block}" >> "$target_file"
            rm -f "${target_file}.bak"
        }
    else
        # Append block to existing instructions
        echo -e "\n\n${block}" >> "$target_file"
    fi
}

# ------------------------------------------------------------------------------
# Install Harness Function
# ------------------------------------------------------------------------------
install_harness() {
    local harness="$1"
    local dest_root="$2"
    local src_root="$SCRIPT_DIR/profiles/$harness"
    local instruction_file="AGENTS.md"
    local agent_subdir="agents"
    local extension=".md"

    if [ "$harness" = "zcode" ]; then
        src_root="$SCRIPT_DIR"
    elif [ "$harness" = "codex" ]; then
        extension=".toml"
    elif [ "$harness" = "claude" ]; then
        instruction_file="CLAUDE.md"
    elif [ "$harness" = "cursor" ]; then
        instruction_file="tauri-pack-guide.md"
    elif [ "$harness" = "gemini" ]; then
        instruction_file="GEMINI.md"
    elif [ "$harness" = "copilot" ]; then
        instruction_file="tauri-pack-guide.md"
        extension=".agent.md"
    elif [ "$harness" = "hermes" ]; then
        instruction_file="tauri-pack-guide.md"
        agent_subdir="tauri-pack/roles"
    fi

    local target_agents_dir="$dest_root/$agent_subdir"
    local src_agents_dir="$src_root/$agent_subdir"

    echo -e "${CYAN}Installing for ${BOLD}${harness}${RESET} at: ${dest_root}"

    # Backup if destination exists
    local backup_id
    backup_id="$(date +%Y%m%d-%H%M%S)-$$"
    local backup_dir="$dest_root/backups/tauri-pack/$backup_id"

    mkdir -p "$target_agents_dir"

    # Copy / update instruction file
    if [ -f "$src_root/$instruction_file" ]; then
        local target_inst="$dest_root/$instruction_file"
        if [ -f "$target_inst" ]; then
            mkdir -p "$backup_dir"
            cp "$target_inst" "$backup_dir/"
        fi
        merge_instructions "$target_inst" "$src_root/$instruction_file"
    fi

    # Copy agent definitions
    local count=0
    for file in "$src_agents_dir"/*"$extension"; do
        if [ -f "$file" ]; then
            local fname
            fname="$(basename "$file")"
            local target_file="$target_agents_dir/$fname"

            if [ -f "$target_file" ]; then
                local old_hash new_hash
                old_hash="$(calc_sha256 "$target_file")"
                new_hash="$(calc_sha256 "$file")"
                if [ "$old_hash" != "$new_hash" ]; then
                    mkdir -p "$backup_dir"
                    cp "$target_file" "$backup_dir/"
                    cp "$file" "$target_file"
                    ((count++))
                fi
            else
                cp "$file" "$target_file"
                ((count++))
            fi
        fi
    done

    echo -e "  ${GREEN}✓ Done:${RESET} Installed/updated ${count} agents."
    if [ -d "$backup_dir" ]; then
        echo -e "  ${YELLOW}ℹ Backup created at:${RESET} ${backup_dir}"
    fi
}

# ------------------------------------------------------------------------------
# Detection & Execution
# ------------------------------------------------------------------------------
HOME_DIR="${HOME:-~}"
DETECTED_HARNESSES=()

check_target() {
    local harness="$1"
    local dir="$2"
    local cli="$3"
    local is_detected=false

    if [ -d "$dir" ]; then
        is_detected=true
    elif [ -n "$cli" ] && command -v "$cli" >/dev/null 2>&1; then
        is_detected=true
    fi

    if [ "$is_detected" = true ]; then
        DETECTED_HARNESSES+=("$harness:$dir")
        echo -e "  ${GREEN}[FOUND]${RESET} ${BOLD}${harness}${RESET} -> ${dir}"
    else
        echo -e "  ${YELLOW}[SKIP]${RESET}  ${harness} (directory not found)"
    fi
}

echo -e "${BOLD}Scanning for supported AI environments...${RESET}"
check_target "cursor"   "$HOME_DIR/.cursor" "cursor"
check_target "claude"   "${CLAUDE_CONFIG_DIR:-$HOME_DIR/.claude}" "claude"
check_target "codex"    "${CODEX_HOME:-$HOME_DIR/.codex}" "codex"
check_target "copilot"  "$HOME_DIR/.copilot" ""
check_target "gemini"   "$HOME_DIR/.gemini" "gemini"
check_target "opencode" "${XDG_CONFIG_HOME:-$HOME_DIR/.config}/opencode" "opencode"
check_target "zcode"    "$HOME_DIR/.zcode" "zcode"
check_target "hermes"   "${HERMES_HOME:-$HOME_DIR/.hermes}" "hermes"

echo ""

if [ ${#DETECTED_HARNESSES[@]} -eq 0 ]; then
    echo -e "${YELLOW}No AI environment folders automatically detected.${RESET}"
    echo -e "You can install directly for your favorite editor by specifying the target, for example:"
    echo -e "  ${BOLD}./install.sh cursor${RESET}  or  ${BOLD}./install.sh claude${RESET}\n"
    
    read -rp "Would you like to install for Cursor & Claude anyway? [y/N]: " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        install_harness "cursor" "$HOME_DIR/.cursor"
        install_harness "claude" "${CLAUDE_CONFIG_DIR:-$HOME_DIR/.claude}"
    fi
    exit 0
fi

# If argument specified
if [ $# -ge 1 ]; then
    TARGET_ARG="$1"
    case "$TARGET_ARG" in
        cursor)   install_harness "cursor" "$HOME_DIR/.cursor" ;;
        claude)   install_harness "claude" "${CLAUDE_CONFIG_DIR:-$HOME_DIR/.claude}" ;;
        codex)    install_harness "codex" "${CODEX_HOME:-$HOME_DIR/.codex}" ;;
        copilot)  install_harness "copilot" "$HOME_DIR/.copilot" ;;
        gemini)   install_harness "gemini" "$HOME_DIR/.gemini" ;;
        opencode) install_harness "opencode-v1" "${XDG_CONFIG_HOME:-$HOME_DIR/.config}/opencode" ;;
        zcode)    install_harness "zcode" "$HOME_DIR/.zcode" ;;
        hermes)   install_harness "hermes" "${HERMES_HOME:-$HOME_DIR/.hermes}" ;;
        all)
            for item in "${DETECTED_HARNESSES[@]}"; do
                h="${item%%:*}"
                d="${item#*:}"
                [ "$h" = "opencode" ] && h="opencode-v1"
                install_harness "$h" "$d"
            done
            ;;
        *)
            echo -e "${RED}Unknown target: $TARGET_ARG${RESET}"
            echo "Available: cursor, claude, codex, copilot, gemini, opencode, zcode, hermes, all"
            exit 1
            ;;
    esac
else
    # Auto install for all detected targets
    echo -e "${BOLD}Installing into all detected environments...${RESET}\n"
    for item in "${DETECTED_HARNESSES[@]}"; do
        h="${item%%:*}"
        d="${item#*:}"
        [ "$h" = "opencode" ] && h="opencode-v1"
        install_harness "$h" "$d"
    done
fi

echo -e "\n${BOLD}${GREEN}✔ Installation completed successfully!${RESET}"
echo -e "Open a NEW chat in your AI editor and verify the 10 ${CYAN}tauri-*${RESET} subagents."
