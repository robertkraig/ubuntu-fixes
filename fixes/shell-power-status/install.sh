#!/bin/bash
# Run as your regular user, not root (installs to ~/.local/bin and edits your shell rc).
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARK='ubuntu-fixes: power-status'

mkdir -p "$HOME/.local/bin"
install -m 755 "$DIR/power-status.sh" "$HOME/.local/bin/power-status"
echo "==> Installed ~/.local/bin/power-status"

# Make sure the login shell's rc exists, so a fresh machine gets the hook too
case "$(basename "$(getent passwd "$USER" | cut -d: -f7)")" in
    zsh)  touch "$HOME/.zshrc" ;;
    bash) touch "$HOME/.bashrc" ;;
esac

HOOK="# $MARK — show the power profile, battery and GPU state in new terminals
[[ \$- == *i* && -t 1 && -x ~/.local/bin/power-status ]] && ~/.local/bin/power-status"

for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    [ -f "$rc" ] || continue
    # Drop any existing hook (marker line + command line), then re-add it
    awk -v mark="$MARK" 'index($0, mark) { getline; next } { print }' "$rc" > "$rc.tmp"
    if [ "$rc" = "$HOME/.zshrc" ]; then
        # Top of .zshrc: Powerlevel10k instant prompt (and similar) swallows or warns
        # about any console output printed after it starts
        { echo "$HOOK"; echo; sed -e '/./,$!d' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$rc.tmp"; } > "$rc"
        echo "==> power-status hooked at the top of $rc"
    else
        { sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$rc.tmp"; printf '\n%s\n' "$HOOK"; } > "$rc"
        echo "==> power-status hooked in $rc"
    fi
    rm -f "$rc.tmp"
done

echo "==> Done. Open a new terminal, or run: power-status"
"$HOME/.local/bin/power-status"
