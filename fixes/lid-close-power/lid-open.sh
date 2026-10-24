#!/bin/bash
# Called by acpid when lid opens. Restore full performance.

# Log everything to the journal: journalctl -t ubuntu-fixes/lid-open
exec > >(logger -t ubuntu-fixes/lid-open) 2>&1

# Charger name varies (AC, AC0, ADP1, ACAD), so find the Mains supply
ac_online() {
    for ps in /sys/class/power_supply/*; do
        [ "$(cat "$ps/type" 2>/dev/null)" = Mains ] && { cat "$ps/online"; return; }
    done
}

echo "lid opened (AC online=$(ac_online))"

# Re-apply TLP for the actual power source (sets platform profile, EPP, etc.)
profile_before=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null)
/usr/sbin/tlp start
profile_after=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null)
if [ "$profile_before" != "$profile_after" ]; then
    echo "changed: platform_profile $profile_before -> $profile_after"
else
    echo "unchanged: platform_profile already $profile_after"
fi

# Remove CPU power cap — restore the limits lid-closed saved for each RAPL zone
ZONES=$(for z in /sys/class/powercap/intel-rapl*:*; do
    [[ "$(cat "$z/name" 2>/dev/null)" == package-* ]] && echo "$z"
done)
SAVE=/run/lid-close-power.rapl

watts() { awk -v uw="$1" 'BEGIN { printf "%gW", uw / 1e6 }'; }

set_limit() {  # zone, constraint number, microwatts
    local f="$1/constraint_$2_power_limit_uw" name before
    [ -f "$f" ] || return
    name="$(basename "$1") PL$(( $2 + 1 ))"
    before=$(cat "$f")
    if [ "$before" = "$3" ]; then
        echo "unchanged: $name already $(watts "$before")"
    elif echo "$3" > "$f" 2>/dev/null && [ "$(cat "$f")" = "$3" ]; then
        echo "changed: $name $(watts "$before") -> $(watts "$3")"
    else
        echo "unchanged: $name $(watts "$before"), firmware rejected $(watts "$3")"
    fi
}

[ -f "$SAVE" ] || echo "no saved limits in $SAVE, falling back to max_power_uw"
# Last resort for PL2: the highest PL2 saved from any zone. Some firmware reports
# the MSR zone's PL2 (and its max) as 0 while the MMIO zone holds the real value.
best_pl2=$(awk '$3 > 0 { print $3 }' "$SAVE" 2>/dev/null | sort -n | tail -1)
for zone in $ZONES; do
    [ -f "$zone/constraint_0_power_limit_uw" ] || continue
    read -r _ pl1 pl2 < <(grep "^$zone " "$SAVE" 2>/dev/null)
    # Never write 0: a zero PL2 pins the CPU at its minimum frequency.
    [ "${pl1:-0}" -gt 0 ] || pl1=$(cat "$zone/constraint_0_max_power_uw" 2>/dev/null)
    [ "${pl2:-0}" -gt 0 ] || pl2=$(cat "$zone/constraint_1_max_power_uw" 2>/dev/null)
    [ "${pl2:-0}" -gt 0 ] || pl2=$best_pl2
    for c in 0 1; do
        v=$pl1; [ "$c" -eq 1 ] && v=$pl2
        if [ "${v:-0}" -gt 0 ]; then
            set_limit "$zone" "$c" "$v"
        else
            echo "unchanged: $(basename "$zone") PL$(( c + 1 )) no known good value, left at $(watts "$(cat "$zone/constraint_${c}_power_limit_uw")")"
        fi
    done
done
rm -f "$SAVE"
