#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.

IFACE=$(basename "$(dirname "$(ls -d /sys/class/net/*/wireless 2>/dev/null | head -1)")")
[ -n "$IFACE" ] && [ "$IFACE" != "." ] || { echo "no wireless interface"; exit 1; }

MODULE=$(basename "$(readlink -f "/sys/class/net/$IFACE/device/driver/module")")

if systemctl is-enabled wifi-sleep-unload.service >/dev/null 2>&1; then
    echo "already installed for $IFACE ($MODULE)"
    exit 2
fi

case "$MODULE" in
    iwlwifi) echo "Intel WiFi ($IFACE, iwlwifi): known resume hang on AX2xx/AX1xx"; exit 0 ;;
    *)       echo "WiFi driver $MODULE is not known to be affected (iwlwifi is)"; exit 1 ;;
esac
