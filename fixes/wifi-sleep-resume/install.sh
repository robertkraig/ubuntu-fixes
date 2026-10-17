#!/bin/bash
set -e

# Detect WiFi interface automatically
IFACE=$(ip link show | grep -E "wlp|wlan" | grep -v "p2p" | awk -F': ' '{print $2}' | head -1)

if [ -z "$IFACE" ]; then
    echo "ERROR: Could not detect WiFi interface. Edit wifi-cycle manually and set IFACE."
    exit 1
fi

echo "==> Detected WiFi interface: $IFACE"

# Update interface name in the script
sed "s/IFACE=\"wlp147s0f0\"/IFACE=\"$IFACE\"/" wifi-cycle > /tmp/wifi-cycle-patched

echo "==> Installing sleep hook to /usr/lib/systemd/system-sleep/wifi-cycle..."
cp /tmp/wifi-cycle-patched /usr/lib/systemd/system-sleep/wifi-cycle
chmod +x /usr/lib/systemd/system-sleep/wifi-cycle

echo "==> Done. No reboot required."
echo "    Hook will cycle $IFACE on suspend/resume when on battery."
