#!/bin/bash
# Called by acpid when lid closes. Reduce heat aggressively.

# Log everything to the journal: journalctl -t ubuntu-fixes/lid-closed
exec > >(logger -t ubuntu-fixes/lid-closed) 2>&1

echo "lid closed (AC online=$(cat /sys/class/power_supply/AC/online 2>/dev/null))"

/usr/sbin/tlp bat

# Force low-power platform profile
echo low-power > /sys/firmware/acpi/platform_profile 2>/dev/null || true
echo "platform_profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null)"

# Cap CPU package power (RAPL): 15W sustained, 20W burst (PL1/PL2)
# This is the biggest single lever for heat reduction under lid.
# Save the current limits first so lid-open can restore them exactly —
# constraint_*_max_power_uw is unreliable (reads 0 for PL2 on some firmware,
# and writing that back pins the CPU at minimum frequency).
SAVE=/run/lid-close-power.rapl
for zone in /sys/class/powercap/intel-rapl/intel-rapl:0; do
    # Don't overwrite on repeated close events — that would save our own cap.
    # A zero limit is never saved: lid-open falls back to firmware values instead.
    if [ -f "$SAVE" ]; then
        echo "keeping saved limits: $(tr '\n' ' ' < "$SAVE")"
    else
        pl1=$(cat "$zone/constraint_0_power_limit_uw" 2>/dev/null)
        pl2=$(cat "$zone/constraint_1_power_limit_uw" 2>/dev/null)
        {
            [ "${pl1:-0}" -gt 0 ] && echo "PL1=$pl1"
            [ "${pl2:-0}" -gt 0 ] && echo "PL2=$pl2"
        } > "$SAVE"
        echo "saved limits: $(tr '\n' ' ' < "$SAVE")"
    fi
    [ -f "$zone/constraint_0_power_limit_uw" ] && echo 15000000 > "$zone/constraint_0_power_limit_uw" || true
    [ -f "$zone/constraint_1_power_limit_uw" ] && echo 20000000 > "$zone/constraint_1_power_limit_uw" || true
    echo "capped: PL1=$(cat "$zone/constraint_0_power_limit_uw") PL2=$(cat "$zone/constraint_1_power_limit_uw")"
done
