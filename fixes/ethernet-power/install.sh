#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/deploy.sh"

rc=0; reason=$("$DIR/applies.sh") || rc=$?
[ "$rc" -eq 1 ] && { echo "Skipping: $reason"; exit 0; }
[ "$rc" -eq 2 ] && { echo "Already applied: $reason"; exit 0; }

echo "==> Installing ethernet power script..."
deploy_file "$DIR/ethernet-power.sh" /usr/local/bin/ethernet-power "" 755

echo "==> Installing udev rule..."
deploy_file "$DIR/99-ethernet-power.rules" /etc/udev/rules.d/99-ethernet-power.rules "" 644
udevadm control --reload-rules

echo "==> Installing shell aliases (eth-up / eth-down)..."
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
ZSHRC="$REAL_HOME/.zshrc"
SNIPPET="[ -f /usr/local/share/ethernet-aliases.zsh ] && source /usr/local/share/ethernet-aliases.zsh"
install -m 644 "$DIR/ethernet-aliases.zsh" /usr/local/share/ethernet-aliases.zsh
grep -qF 'ethernet-aliases.zsh' "$ZSHRC" 2>/dev/null || echo "$SNIPPET" >> "$ZSHRC"

echo "==> Applying now..."
/usr/local/bin/ethernet-power

echo "==> Done. Wired ethernet downs on battery with no cable. Use eth-up / eth-down to toggle."
