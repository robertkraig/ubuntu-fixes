#!/bin/bash
# Exit 0 = applies/needs update, 1 = not applicable, 2 = already applied.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/deploy.sh"

ls /proc/acpi/button/lid/*/state >/dev/null 2>&1 || { echo "no laptop lid"; exit 1; }
command -v tlp >/dev/null || { echo "needs TLP (run tlp-battery first)"; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

stale=()
file_current "$DIR/lid-closed.sh"   /usr/local/bin/lid-closed          || stale+=("lid-closed")
file_current "$DIR/lid-open.sh"     /usr/local/bin/lid-open            || stale+=("lid-open")
file_current "$DIR/acpi-lid.event"  /etc/acpi/events/lid-close-power   || stale+=("acpid-event")
file_current "$DIR/acpi-lid.sh"     /etc/acpi/lid.sh                   || stale+=("acpid-handler")
[ -f /etc/udev/rules.d/99-lid-tlp.rules ] && stale+=("old udev rule")

if [ ${#stale[@]} -eq 0 ] && systemctl is-active acpid >/dev/null 2>&1; then
    echo "already installed"
    exit 2
fi

[ -f /etc/acpi/events/lid-close-power ] && echo "installed but stale: ${stale[*]}" || \
    echo "laptop lid + TLP"
exit 0
