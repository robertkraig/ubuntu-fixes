#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.

command -v plasmashell >/dev/null 2>&1 || { echo "KDE Plasma not installed"; exit 1; }

SCRIPT="$HOME/.local/bin/kde-power-effects.sh"
SERVICE="$HOME/.config/systemd/user/kde-power-effects.service"
UDEV="/etc/udev/rules.d/99-kde-power-effects.rules"

[ -f "$SCRIPT" ] && [ -f "$SERVICE" ] && [ -f "$UDEV" ] && \
    { echo "already applied: script, systemd service, and udev rule installed"; exit 2; }

echo "KDE Plasma detected, power-aware effects not installed"
exit 0
