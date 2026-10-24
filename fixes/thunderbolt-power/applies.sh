#!/bin/bash
# Exit 0 = applies/needs update, 1 = not applicable, 2 = already applied.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/deploy.sh"

# Same name match as the udev rule (both read the PCI ID database)
lspci | grep -qiE 'thunderbolt|usb4' || { echo "no Thunderbolt/USB4 controllers found"; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file_current "$DIR/99-thunderbolt-pm.rules" /etc/udev/rules.d/99-thunderbolt-pm.rules || {
    [ -f /etc/udev/rules.d/99-thunderbolt-pm.rules ] && echo "installed but stale" || echo "Thunderbolt/USB4 controllers found, runtime PM not configured"
    exit 0
}

echo "already applied"
exit 2
