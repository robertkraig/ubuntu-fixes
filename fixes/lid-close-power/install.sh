#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/deploy.sh"

rc=0; reason=$("$DIR/applies.sh") || rc=$?
[ "$rc" -eq 1 ] && { echo "Skipping: $reason"; exit 0; }
[ "$rc" -eq 2 ] && { echo "Already applied: $reason"; exit 0; }

echo "==> Installing lid close power scripts..."
deploy_file "$DIR/lid-closed.sh" /usr/local/bin/lid-closed "" 755
deploy_file "$DIR/lid-open.sh"   /usr/local/bin/lid-open   "" 755

echo "==> Installing acpid event handler..."
if ! command -v acpid >/dev/null 2>&1; then
    apt-get install -y acpid
fi
deploy_file "$DIR/acpi-lid.event" /etc/acpi/events/lid-close-power "" 644
deploy_file "$DIR/acpi-lid.sh"    /etc/acpi/lid.sh                  "" 755
systemctl enable --now acpid

echo "==> Done. Close the lid to test — CPU will be capped at 15W."
