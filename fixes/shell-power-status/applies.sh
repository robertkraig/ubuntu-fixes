#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/deploy.sh"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ls /sys/class/power_supply/BAT* >/dev/null 2>&1 || { echo "no battery (not a laptop)"; exit 1; }

MARK='ubuntu-fixes: power-status'
stale=()
file_current "$DIR/power-status.sh" "$HOME/.local/bin/power-status" || stale+=("script")
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    [ -f "$rc" ] || continue
    grep -q "$MARK" "$rc" || stale+=("$(basename "$rc") not hooked")
done
# zsh: the hook must come before any prompt framework init (p10k instant prompt
# swallows later output), so it belongs on the first line
[ -f "$HOME/.zshrc" ] && grep -q "$MARK" "$HOME/.zshrc" \
    && ! head -1 "$HOME/.zshrc" | grep -q "$MARK" && stale+=(".zshrc hook not at top")
login_shell=$(basename "$(getent passwd "$USER" | cut -d: -f7)")
case "$login_shell" in
    zsh|bash) [ -f "$HOME/.${login_shell}rc" ] || stale+=("no ~/.${login_shell}rc") ;;
esac

if [ ${#stale[@]} -eq 0 ]; then
    echo "already applied: power-status runs in new terminals"
    exit 2
fi

[ -f "$HOME/.local/bin/power-status" ] && echo "installed but stale: ${stale[*]}" || echo "laptop, no power status in new terminals"
exit 0
