#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/deploy.sh"

rc=0; reason=$("$DIR/applies.sh") || rc=$?
[ "$rc" -eq 1 ] && { echo "Skipping: $reason"; exit 0; }
[ "$rc" -eq 2 ] && { echo "Already applied: $reason"; exit 0; }

echo "==> Installing ethernet power script..."
deploy_file "$DIR/ethernet-power.sh" /usr/local/bin/ethernet-power "" 755

echo "==> Installing udev rule..."
deploy_file "$DIR/99-ethernet-power.rules" /etc/udev/rules.d/99-ethernet-power.rules "" 644
udevadm control --reload-rules

echo "==> Applying now..."
/usr/local/bin/ethernet-power

echo "==> Done. Wired ethernet will down when on battery with no cable plugged in."
