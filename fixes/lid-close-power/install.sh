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

# Older version of this fix used a udev rule; acpid replaced it
if [ -f /etc/udev/rules.d/99-lid-tlp.rules ]; then
    rm /etc/udev/rules.d/99-lid-tlp.rules
    udevadm control --reload
    echo "==> Removed old /etc/udev/rules.d/99-lid-tlp.rules"
fi

# Which RAPL zones accept a power limit? Write each current PL1 back to itself.
echo "==> Checking which CPU power limit interfaces accept writes..."
capped=0
for zone in /sys/class/powercap/intel-rapl/intel-rapl:0 /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0; do
    f="$zone/constraint_0_power_limit_uw"
    [ -f "$f" ] || continue
    if cat "$f" > "$f" 2>/dev/null; then
        echo "    $(basename "$zone"): writable"
        capped=1
    else
        echo "    $(basename "$zone"): rejected by firmware"
    fi
done

if [ "$capped" -eq 1 ]; then
    echo "==> Done. Close the lid to test — CPU will be capped at 15W."
else
    echo "==> Done. CPU power limits are locked by firmware, so lid close only switches"
    echo "    TLP to battery settings and the platform profile, no 15W cap."
fi
echo "    Log: journalctl -t ubuntu-fixes/lid-closed -t ubuntu-fixes/lid-open"
