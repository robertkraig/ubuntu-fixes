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
for id in 9a2b 9a2d 9a1f; do
    addr=$(lspci -n | grep -i "8086:$id" | awk '{print $1}')
    [ -z "$addr" ] && continue
    echo auto > "/sys/bus/pci/devices/0000:$addr/power/control" 2>/dev/null || true
    pwr=$(cat "/sys/bus/pci/devices/0000:$addr/power/runtime_status" 2>/dev/null)
    echo "  0000:$addr → $pwr"
done

echo "==> Done. TB4 controllers will suspend when nothing is connected (~1-2W saved)."
