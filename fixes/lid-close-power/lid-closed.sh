#!/bin/bash
# Called by acpid when lid closes. Reduce heat aggressively.

# Log everything to the journal: journalctl -t ubuntu-fixes/lid-closed
exec > >(logger -t ubuntu-fixes/lid-closed) 2>&1

echo "lid closed (AC online=$(cat /sys/class/power_supply/AC/online 2>/dev/null))"

/usr/sbin/tlp bat

# Lowest platform profile the firmware offers
for want in low-power quiet cool; do
    if grep -qw "$want" /sys/firmware/acpi/platform_profile_choices 2>/dev/null; then
        echo "$want" > /sys/firmware/acpi/platform_profile
        break
    fi
done
echo "platform_profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null)"

# Cap CPU package power (RAPL): 15W sustained, 20W burst (PL1/PL2).
# This is the biggest single lever for heat reduction under lid.
# There are two RAPL interfaces: the MSR zone (intel-rapl) and the MMIO zone
# (intel-rapl-mmio). Firmware may enforce either and reject writes to the other
# (e.g. ENODATA on a disabled MSR zone), so try both and read back the result.
ZONES="/sys/class/powercap/intel-rapl/intel-rapl:0 /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0"
SAVE=/run/lid-close-power.rapl

# Save the current limits so lid-open can restore them exactly. Don't overwrite on
# repeated close events — that would save our own cap. Zero limits are never saved.
if [ -f "$SAVE" ]; then
    echo "keeping saved limits: $(tr '\n' ' ' < "$SAVE")"
else
    for zone in $ZONES; do
        [ -f "$zone/constraint_0_power_limit_uw" ] || continue
        pl1=$(cat "$zone/constraint_0_power_limit_uw" 2>/dev/null)
        pl2=$(cat "$zone/constraint_1_power_limit_uw" 2>/dev/null)
        echo "$zone ${pl1:-0} ${pl2:-0}"
    done > "$SAVE"
    echo "saved limits: $(tr '\n' ' ' < "$SAVE")"
fi

set_limit() {  # zone, constraint number, microwatts
    local f="$1/constraint_$2_power_limit_uw"
    [ -f "$f" ] || return
    if echo "$3" > "$f" 2>/dev/null && [ "$(cat "$f")" = "$3" ]; then
        echo "$(basename "$1") PL$(( $2 + 1 )) capped to $3"
    else
        echo "$(basename "$1") PL$(( $2 + 1 )) write rejected by firmware, still $(cat "$f")"
    fi
}

for zone in $ZONES; do
    set_limit "$zone" 0 15000000
    set_limit "$zone" 1 20000000
done
