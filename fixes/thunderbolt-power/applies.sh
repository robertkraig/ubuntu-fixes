#!/bin/bash
# Exit 0 = applies/needs update, 1 = not applicable, 2 = already applied.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/deploy.sh"

# Check for any of the three TB4 device IDs
found=0
for id in 9a2b 9a2d 9a1f; do
    lspci -n | grep -qi "8086:$id" && found=1
done
[ "$found" -eq 1 ] || { echo "no Tiger Lake TB4 controllers found"; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file_current "$DIR/99-thunderbolt-pm.rules" /etc/udev/rules.d/99-thunderbolt-pm.rules || {
    [ -f /etc/udev/rules.d/99-thunderbolt-pm.rules ] && echo "installed but stale" || echo "TB4 controllers found, runtime PM not configured"
    exit 0
}

echo "already applied"
exit 2
