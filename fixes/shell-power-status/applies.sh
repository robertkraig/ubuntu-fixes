#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/deploy.sh"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ls /sys/class/power_supply/BAT* >/dev/null 2>&1 || { echo "no battery (not a laptop)"; exit 1; }

hooked=0
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    grep -qs 'ubuntu-fixes: power-status' "$rc" && hooked=1
done

if file_current "$DIR/power-status.sh" "$HOME/.local/bin/power-status" && [ "$hooked" -eq 1 ]; then
    echo "already applied: power-status runs in new terminals"
    exit 2
fi

[ -f "$HOME/.local/bin/power-status" ] && echo "installed but stale" || echo "laptop, no power status in new terminals"
exit 0
