#!/bin/bash
# Run as your regular user, not root (installs to ~/.local/bin and edits your shell rc).
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.local/bin"
install -m 755 "$DIR/power-status.sh" "$HOME/.local/bin/power-status"
echo "==> Installed ~/.local/bin/power-status"

for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    [ -f "$rc" ] || continue
    grep -q 'ubuntu-fixes: power-status' "$rc" && { echo "==> Already hooked in $rc"; continue; }
    cat >> "$rc" <<'HOOK'

# ubuntu-fixes: power-status — show the power profile, battery and GPU state in new terminals
[[ $- == *i* && -t 1 && -x ~/.local/bin/power-status ]] && ~/.local/bin/power-status
HOOK
    echo "==> Added power-status to $rc"
done

echo "==> Done. Open a new terminal, or run: power-status"
"$HOME/.local/bin/power-status"
