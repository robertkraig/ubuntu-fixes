#!/bin/bash
# Bring wired ethernet down when on battery with no cable, up on AC.
# Called by: udev on power source change, NetworkManager dispatcher on carrier change.

# Log everything to the journal: journalctl -t ubuntu-fixes/ethernet-power
exec > >(logger -t ubuntu-fixes/ethernet-power) 2>&1

# Charger name varies (AC, AC0, ADP1, ACAD), so find the Mains supply
ac_online() {
    for ps in /sys/class/power_supply/*; do
        [ "$(cat "$ps/type" 2>/dev/null)" = Mains ] && { cat "$ps/online"; return; }
    done
}

# No Mains supply at all (desktop) counts as AC
on_ac() {
    [ "$(ac_online)" != 0 ]
}

for iface in $(ls /sys/class/net/); do
    # Skip loopback, WiFi, virtual interfaces
    [ -d "/sys/class/net/$iface/wireless" ] && continue
    [ "$iface" = "lo" ] && continue
    [ -d "/sys/class/net/$iface/bridge" ] && continue
    readlink "/sys/class/net/$iface" | grep -qE 'virtual|veth|docker|br-' && continue

    carrier=$(cat "/sys/class/net/$iface/carrier" 2>/dev/null || echo 0)
    state=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null)

    if on_ac || [ "$carrier" = "1" ]; then
        want=up
    else
        want=down
    fi
    # udev fires this on every net change, so only log when something changes
    if { [ "$want" = up ] && [ "$state" = down ]; } || { [ "$want" = down ] && [ "$state" != down ]; }; then
        echo "$iface: $state -> $want (carrier=$carrier, AC online=$(ac_online))"
    fi
    ip link set "$iface" "$want" || true
done
