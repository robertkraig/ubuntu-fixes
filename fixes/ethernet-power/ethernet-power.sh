#!/bin/bash
# Bring wired ethernet down when on battery with no cable, up on AC.
# Called by: udev on power source change, NetworkManager dispatcher on carrier change.

on_ac() {
    cat /sys/class/power_supply/AC/online 2>/dev/null | grep -q 1
}

for iface in $(ls /sys/class/net/); do
    # Skip loopback, WiFi, virtual interfaces
    [ -d "/sys/class/net/$iface/wireless" ] && continue
    [ "$iface" = "lo" ] && continue
    [ -d "/sys/class/net/$iface/bridge" ] && continue
    readlink "/sys/class/net/$iface" | grep -qE 'virtual|veth|docker|br-' && continue

    carrier=$(cat "/sys/class/net/$iface/carrier" 2>/dev/null || echo 0)

    if on_ac || [ "$carrier" = "1" ]; then
        ip link set "$iface" up 2>/dev/null || true
    else
        ip link set "$iface" down 2>/dev/null || true
    fi
done
