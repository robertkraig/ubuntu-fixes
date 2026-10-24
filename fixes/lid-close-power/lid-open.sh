#!/bin/bash
# Called by acpid when lid opens. Restore full performance.

# Log everything to the journal: journalctl -t ubuntu-fixes/lid-open
exec > >(logger -t ubuntu-fixes/lid-open) 2>&1

echo "lid opened (AC online=$(cat /sys/class/power_supply/AC/online 2>/dev/null))"

# Re-apply TLP for the actual power source (sets platform profile, EPP, etc.)
/usr/sbin/tlp start
echo "platform_profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null)"

# Remove CPU power cap — restore the limits saved by lid-closed
SAVE=/run/lid-close-power.rapl
for zone in /sys/class/powercap/intel-rapl/intel-rapl:0; do
    PL1=; PL2=
    if [ -f "$SAVE" ]; then
        . "$SAVE"
        echo "saved limits: PL1=$PL1 PL2=$PL2"
    else
        echo "no saved limits in $SAVE, falling back to max_power_uw"
    fi
    # Never write 0: a zero PL2 pins the CPU at its minimum frequency.
    # Fallbacks: max_power_uw, then the firmware's own limits in the MMIO zone.
    mmio=/sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0
    [ "${PL1:-0}" -gt 0 ] || PL1=$(cat "$zone/constraint_0_max_power_uw" 2>/dev/null)
    [ "${PL1:-0}" -gt 0 ] || PL1=$(cat "$mmio/constraint_0_power_limit_uw" 2>/dev/null)
    [ "${PL2:-0}" -gt 0 ] || PL2=$(cat "$zone/constraint_1_max_power_uw" 2>/dev/null)
    [ "${PL2:-0}" -gt 0 ] || PL2=$(cat "$mmio/constraint_1_power_limit_uw" 2>/dev/null)
    [ "${PL1:-0}" -gt 0 ] && echo "$PL1" > "$zone/constraint_0_power_limit_uw" || echo "PL1 unknown, leaving as is"
    [ "${PL2:-0}" -gt 0 ] && echo "$PL2" > "$zone/constraint_1_power_limit_uw" || echo "PL2 unknown, leaving as is"
    echo "restored: PL1=$(cat "$zone/constraint_0_power_limit_uw") PL2=$(cat "$zone/constraint_1_power_limit_uw")"
done
rm -f "$SAVE"
