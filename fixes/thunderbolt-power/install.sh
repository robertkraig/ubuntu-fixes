#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/deploy.sh"

rc=0; reason=$("$DIR/applies.sh") || rc=$?
[ "$rc" -eq 1 ] && { echo "Skipping: $reason"; exit 0; }
[ "$rc" -eq 2 ] && { echo "Already applied: $reason"; exit 0; }

echo "==> Installing Thunderbolt runtime PM udev rule..."
deploy_file "$DIR/99-thunderbolt-pm.rules" /etc/udev/rules.d/99-thunderbolt-pm.rules "" 644
udevadm control --reload-rules

echo "==> Applying to already-present devices..."
lspci -D | grep -iE 'thunderbolt|usb4' | while read -r addr name; do
    echo auto > "/sys/bus/pci/devices/$addr/power/control" 2>/dev/null || true
    pwr=$(cat "/sys/bus/pci/devices/$addr/power/runtime_status" 2>/dev/null)
    echo "  $addr ${name#*: } → $pwr"
done

echo "==> Done. Thunderbolt/USB4 controllers will suspend when nothing is connected (~1-2W saved)."
