#!/bin/bash
# Called by acpid when lid closes. Reduce heat aggressively.

# Log everything to the journal: journalctl -t ubuntu-fixes/lid-closed
exec > >(logger -t ubuntu-fixes/lid-closed) 2>&1

# Charger name varies (AC, AC0, ADP1, ACAD), so find the Mains supply
ac_online() {
    for ps in /sys/class/power_supply/*; do
        [ "$(cat "$ps/type" 2>/dev/null)" = Mains ] && { cat "$ps/online"; return; }
    done
}

echo "lid closed (AC online=$(ac_online))"

profile_before=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null)
/usr/sbin/tlp bat

# Lowest platform profile the firmware offers. tlp bat may already have set one,
# so log the profile from before TLP ran.
for want in low-power quiet cool; do
    if grep -qw "$want" /sys/firmware/acpi/platform_profile_choices 2>/dev/null; then
        echo "$want" > /sys/firmware/acpi/platform_profile
        break
    fi
done
profile_after=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null)
if [ "$profile_before" != "$profile_after" ]; then
    echo "changed: platform_profile $profile_before -> $profile_after"
else
    echo "unchanged: platform_profile already $profile_after"
fi

# Cap CPU package power (RAPL): 15W sustained, 20W burst (PL1/PL2).
# This is the biggest single lever for heat reduction under lid.
# There are two RAPL interfaces: the MSR zone (intel-rapl:N) and the MMIO zone
# (intel-rapl-mmio:N), one per CPU package. AMD CPUs register under intel-rapl too.
# Firmware may enforce either and reject writes to the other (e.g. ENODATA on a
# disabled MSR zone), so try every package zone and read back the result.
ZONES=$(for z in /sys/class/powercap/intel-rapl*:*; do
    [[ "$(cat "$z/name" 2>/dev/null)" == package-* ]] && echo "$z"
done)
SAVE=/run/lid-close-power.rapl

# Save the current limits so lid-open can restore them exactly. Don't overwrite on
# repeated close events — that would save our own cap. A zero is saved as-is and
# lid-open treats it as unknown.
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

for zone in $ZONES; do
    set_limit "$zone" 0 15000000
    set_limit "$zone" 1 20000000
done
