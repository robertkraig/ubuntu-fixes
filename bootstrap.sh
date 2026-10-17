#!/bin/bash
# bootstrap.sh — Plugin-driven Ubuntu setup
# Reads plugins/*.json and installs each one.
# Usage: sudo ./bootstrap.sh [--only plugin-name] [--skip plugin-name]
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$SCRIPT_DIR/plugins"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
UBUNTU_CODENAME=$(lsb_release -cs)
ACTUAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~"$ACTUAL_USER")

export DEBIAN_FRONTEND=noninteractive

# ─── Args ─────────────────────────────────────────────────────────────────────

ONLY=""
SKIP=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --only) ONLY="$2"; shift 2 ;;
        --skip) SKIP="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ─── Helpers ──────────────────────────────────────────────────────────────────

info()    { echo -e "\e[34m==>\e[0m $*"; }
success() { echo -e "\e[32m ✓\e[0m $*"; }
warn()    { echo -e "\e[33m  !\e[0m $*"; }
die()     { echo -e "\e[31mERROR:\e[0m $*"; exit 1; }

[ "$EUID" -eq 0 ] || die "Run with sudo."
command -v jq >/dev/null || apt-get install -y -qq jq

pkg_installed() { dpkg -l "$1" 2>/dev/null | grep -q "^ii"; }

# Substitutes {{CODENAME}} and {{USER_HOME}} in strings
interpolate() {
    echo "$1" \
        | sed "s|{{CODENAME}}|$UBUNTU_CODENAME|g" \
        | sed "s|{{USER_HOME}}|$USER_HOME|g" \
        | sed "s|{{USER}}|$ACTUAL_USER|g"
}

# ─── Plugin handlers ──────────────────────────────────────────────────────────

handle_repo() {
    # Returns 0 if repo was newly added (caller should apt-get update),
    # 1 if already present (skipped).
    local plugin="$1"
    local type sources_file

    type=$(echo "$plugin" | jq -r '.repo.type // empty')
    [ -z "$type" ] && return 1

    sources_file=$(interpolate "$(echo "$plugin" | jq -r '.repo.sources_file // empty')")

    case "$type" in
        apt-key|apt-key-dearmor)
            [ -n "$sources_file" ] && [ -f "$sources_file" ] && return 1
            local gpg_url gpg_keyring line
            gpg_url=$(echo "$plugin"     | jq -r '.repo.gpg_url')
            gpg_keyring=$(echo "$plugin" | jq -r '.repo.gpg_keyring')
            line=$(interpolate "$(echo "$plugin" | jq -r '.repo.line')")
            curl -fsSL "$gpg_url" | gpg --yes --dearmor -o "$gpg_keyring"
            echo "$line" > "$sources_file"
            ;;
        ppa)
            local ppa
            ppa=$(echo "$plugin" | jq -r '.repo.ppa')
            apt-cache policy 2>/dev/null | grep -q "${ppa#ppa:}" && return 1
            add-apt-repository -y "$ppa"
            ;;
        script)
            local script
            script=$(echo "$plugin" | jq -r '.repo.script')
            bash -c "$(interpolate "$script")"
            ;;
    esac
    return 0
}

handle_packages() {
    local plugin="$1"
    local packages missing=()

    packages=$(echo "$plugin" | jq -r '.packages[]? // empty')
    [ -z "$packages" ] && return 0

    while IFS= read -r pkg; do
        pkg_installed "$pkg" || missing+=("$pkg")
    done <<< "$packages"

    [ ${#missing[@]} -eq 0 ] && return 0
    apt-get install -y "${missing[@]}"
}

handle_manual() {
    local plugin="$1"
    local script

    script=$(echo "$plugin" | jq -r '.manual_script // empty')
    [ -z "$script" ] && return 0

    local full_path="$SCRIPTS_DIR/$script"
    [ -f "$full_path" ] || { warn "Manual script not found: $full_path"; return 1; }
    bash "$full_path" "$ACTUAL_USER" "$USER_HOME"
}

handle_post_install() {
    local plugin="$1"
    local cmds

    cmds=$(echo "$plugin" | jq -r '.post_install[]? // empty')
    [ -z "$cmds" ] && return 0

    while IFS= read -r cmd; do
        bash -c "$(interpolate "$cmd")"
    done <<< "$cmds"
}

# ─── Main loop ────────────────────────────────────────────────────────────────

REPOS_ADDED=0

# First pass: set up all repos
for plugin_file in "$PLUGINS_DIR"/*.json; do
    plugin=$(cat "$plugin_file")
    name=$(echo "$plugin" | jq -r '.name')
    enabled=$(echo "$plugin" | jq -r '.enabled // true')

    [ "$enabled" = "false" ] && continue
    [ -n "$ONLY" ] && [ "$name" != "$ONLY" ] && continue
    [ -n "$SKIP" ] && [ "$name" = "$SKIP" ] && continue

    repo_type=$(echo "$plugin" | jq -r '.repo.type // empty')
    [ -z "$repo_type" ] && continue

    info "Repo: $name"
    if handle_repo "$plugin"; then
        success "Added repo: $name"
        REPOS_ADDED=$((REPOS_ADDED + 1))
    else
        success "Repo already present: $name"
    fi
done

if [ "$REPOS_ADDED" -gt 0 ]; then
    info "Added $REPOS_ADDED new repo(s), running apt-get update..."
    apt-get update -qq
else
    info "All repos already present, skipping apt-get update"
fi

# Second pass: install packages + manual + post-install
for plugin_file in "$PLUGINS_DIR"/*.json; do
    plugin=$(cat "$plugin_file")
    name=$(echo "$plugin" | jq -r '.name')
    enabled=$(echo "$plugin" | jq -r '.enabled // true')
    description=$(echo "$plugin" | jq -r '.description // .name')

    [ "$enabled" = "false" ] && continue
    [ -n "$ONLY" ] && [ "$name" != "$ONLY" ] && continue
    [ -n "$SKIP" ] && [ "$name" = "$SKIP" ] && continue

    info "Installing: $description"
    handle_packages "$plugin"
    handle_manual "$plugin"
    handle_post_install "$plugin"
    success "$name"
done

echo ""
echo -e "\e[32m Bootstrap complete!\e[0m"
echo "  Run: sudo ./bootstrap.sh --only <name>  to install a single plugin"
echo "  Run: sudo ./bootstrap.sh --skip <name>  to skip a plugin"
echo ""
