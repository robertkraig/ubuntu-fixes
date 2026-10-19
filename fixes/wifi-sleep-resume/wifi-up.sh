#!/bin/bash
# Bring WiFi back after a resume where the driver didn't reload.
# Usage: sudo ./wifi-up.sh   (installed as /usr/local/bin/wifi-up)

[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

SERVICE=wifi-sleep-unload.service

# The interface is gone while the driver is unloaded, so find the driver from
# the installed service, then a live interface, then lspci.
MODULE=$(systemctl cat "$SERVICE" 2>/dev/null | sed -n 's|^ExecStop=.*modprobe \(.*\)$|\1|p')
if [ -z "$MODULE" ]; then
    WDIR=$(ls -d /sys/class/net/*/wireless 2>/dev/null | head -1)
    [ -n "$WDIR" ] && MODULE=$(basename "$(readlink -f "$(dirname "$WDIR")/device/driver/module")")
fi
if [ -z "$MODULE" ]; then
    MODULE=$(lspci -k | grep -A3 -i 'network controller' | sed -n 's/.*Kernel modules: *\([^ ,]*\).*/\1/p' | head -1)
fi
[ -n "$MODULE" ] || { echo "ERROR: can't tell which WiFi driver to load."; exit 1; }

# Find the PCI address for this WiFi card (needed for PCI reset)
PCI_ADDR=$(lspci -k | grep -B1 "Kernel modules:.*${MODULE%%_*}" | grep -oP '[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f]' | head -1)

# Check for PCI wedge: HW_REV=0xFFFFFFFF means the card isn't responding on PCI.
# A module reload alone won't fix this — need a PCI reset first.
pci_wedged() {
    [ -n "$PCI_ADDR" ] || return 1
    dmesg | tail -50 | grep -q "HW_REV=0xFFFFFFFF"
}

if pci_wedged; then
    echo "==> PCI bus wedge detected (HW_REV=0xFFFFFFFF) — resetting PCI device $PCI_ADDR"
    # Unload module first if loaded
    if grep -q "^$MODULE " /proc/modules; then
        for h in /sys/module/"$MODULE"/holders/*; do
            [ -e "$h" ] && rmmod "$(basename "$h")" 2>/dev/null || true
        done
        rmmod "$MODULE" 2>/dev/null || true
        sleep 1
    fi
    # Remove from PCI bus, reset, re-add
    echo 1 > "/sys/bus/pci/devices/$PCI_ADDR/remove" 2>/dev/null || true
    sleep 1
    echo 1 > /sys/bus/pci/rescan
    sleep 2
elif grep -q "^$MODULE " /proc/modules && ! ls -d /sys/class/net/*/wireless >/dev/null 2>&1; then
    # Loaded but no wireless interface: wedged driver, reload from scratch
    echo "==> $MODULE is loaded but no WiFi interface exists, unloading it"
    for h in /sys/module/"$MODULE"/holders/*; do
        [ -e "$h" ] && rmmod "$(basename "$h")"
    done
    rmmod "$MODULE"
    sleep 1
fi

echo "==> Loading $MODULE"
modprobe "$MODULE"

# A failed sleep service skips its reload on the next resume, so clear it
systemctl reset-failed "$SERVICE" 2>/dev/null || true

rfkill unblock wifi 2>/dev/null || true
command -v nmcli >/dev/null && nmcli radio wifi on

for _ in $(seq 10); do
    WDIR=$(ls -d /sys/class/net/*/wireless 2>/dev/null | head -1)
    [ -n "$WDIR" ] && break
    sleep 1
done
if [ -z "$WDIR" ]; then
    echo "ERROR: no WiFi interface after loading $MODULE. Check: journalctl -b -k | grep -i ${MODULE%%_*}"
    exit 1
fi
IFACE=$(basename "$(dirname "$WDIR")")
echo "==> $IFACE is back"
command -v nmcli >/dev/null && nmcli -t -f DEVICE,STATE,CONNECTION device | grep "^$IFACE:"
exit 0
