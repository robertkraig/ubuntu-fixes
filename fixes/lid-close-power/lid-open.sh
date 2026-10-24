#!/bin/bash
# Called by acpid when lid opens. Restore full performance.

# Log everything to the journal: journalctl -t ubuntu-fixes/lid-open
exec > >(logger -t ubuntu-fixes/lid-open) 2>&1

echo "lid opened (AC online=$(cat /sys/class/power_supply/AC/online 2>/dev/null))"

# Re-apply TLP for the actual power source (sets platform profile, EPP, etc.)
/usr/sbin/tlp start
echo "platform_profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null)"

# Remove CPU power cap — restore the limits lid-closed saved for each RAPL zone
ZONES="/sys/class/powercap/intel-rapl/intel-rapl:0 /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0"
SAVE=/run/lid-close-power.rapl

set_limit() {  # zone, constraint number, microwatts
    local f="$1/constraint_$2_power_limit_uw"
    [ -f "$f" ] || return
    if echo "$3" > "$f" 2>/dev/null && [ "$(cat "$f")" = "$3" ]; then
        echo "$(basename "$1") PL$(( $2 + 1 )) restored to $3"
    else
        echo "$(basename "$1") PL$(( $2 + 1 )) write rejected by firmware, still $(cat "$f")"
    fi
}

[ -f "$SAVE" ] || echo "no saved limits in $SAVE, falling back to max_power_uw"
for zone in $ZONES; do
    [ -f "$zone/constraint_0_power_limit_uw" ] || continue
    read -r _ pl1 pl2 < <(grep "^$zone " "$SAVE" 2>/dev/null)
    # Never write 0: a zero PL2 pins the CPU at its minimum frequency.
    [ "${pl1:-0}" -gt 0 ] || pl1=$(cat "$zone/constraint_0_max_power_uw" 2>/dev/null)
    [ "${pl2:-0}" -gt 0 ] || pl2=$(cat "$zone/constraint_1_max_power_uw" 2>/dev/null)
    for c in 0 1; do
        v=$pl1; [ "$c" -eq 1 ] && v=$pl2
        if [ "${v:-0}" -gt 0 ]; then
            set_limit "$zone" "$c" "$v"
        else
            echo "$(basename "$zone") PL$(( c + 1 )) has no known good value, leaving at $(cat "$zone/constraint_${c}_power_limit_uw")"
        fi
    done
done
rm -f "$SAVE"
