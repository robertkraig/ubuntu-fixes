#!/bin/bash
# Exit 0 = applies/needs update, 1 = not applicable, 2 = already applied.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/deploy.sh"

command -v plasmashell >/dev/null 2>&1 || { echo "KDE Plasma not installed"; exit 1; }

REAL_USER="${SUDO_USER:-$USER}"
BIN="$(getent passwd "$REAL_USER" | cut -d: -f6)/.local/bin"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPT_DST="$BIN/kde-power-effects.sh"
SERVICE_DST="$(getent passwd "$REAL_USER" | cut -d: -f6)/.config/systemd/user/kde-power-effects.service"
UDEV_DST="/etc/udev/rules.d/99-kde-power-effects.rules"

stale=()
file_current "$DIR/kde-power-effects.sh" "$SCRIPT_DST"    || stale+=("script")
deployed_and_current "$DIR/kde-power-effects.service" "$SERVICE_DST" "BIN=$BIN" || stale+=("service")
deployed_and_current "$DIR/99-kde-power-effects.rules" "$UDEV_DST" "USER=$REAL_USER" "BIN=$BIN" || stale+=("udev-rule")

if [ ${#stale[@]} -eq 0 ]; then
    echo "already applied: script, service, and udev rule are current"
    exit 2
fi

[ -f "$SCRIPT_DST" ] && echo "installed but stale: ${stale[*]} — will update" || \
    echo "KDE Plasma detected, power-aware effects not installed"
exit 0
