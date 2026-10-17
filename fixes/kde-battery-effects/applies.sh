#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.

command -v plasmashell >/dev/null 2>&1 || { echo "KDE Plasma not installed"; exit 1; }

SCRIPT="$HOME/.local/bin/kde-power-effects.sh"
SERVICE="$HOME/.config/systemd/user/kde-power-effects.service"
UDEV="/etc/udev/rules.d/99-kde-power-effects.rules"

# The udev rule must point at this user's script (an older install pointed at /root)
if [ -f "$SCRIPT" ] && [ -f "$SERVICE" ] && grep -qs -- "--machine=$USER@ .*$SCRIPT" "$UDEV"; then
    echo "already applied: script, systemd service, and udev rule installed"
    exit 2
fi

[ -f "$UDEV" ] && { echo "installed but broken (udev rule doesn't point at $SCRIPT), reinstall"; exit 0; }

echo "KDE Plasma detected, power-aware effects not installed"
exit 0
