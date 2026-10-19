#!/bin/bash
# Bring WiFi back after a resume where the driver didn't reload.
# Usage: sudo wifi-up   (installed as /usr/local/bin/wifi-up)

[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

SERVICE=wifi-sleep-unload.service

# Module detection: read from the service Description line ("Unload iwlwifi before sleep ...")
MODULE=$(systemctl cat "$SERVICE" 2>/dev/null \
    | sed -n 's/^Description=Unload \([^ ]*\) before.*/\1/p')
if [ -z "$MODULE" ]; then
    WDIR=$(ls -d /sys/class/net/*/wireless 2>/dev/null | head -1)
    [ -n "$WDIR" ] && MODULE=$(basename "$(readlink -f "$(dirname "$WDIR")/device/driver/module")")
fi
if [ -z "$MODULE" ]; then
    MODULE=$(lspci -k | grep -A3 -i 'network controller' \
        | sed -n 's/.*Kernel modules: *\([^ ,]*\).*/\1/p' | head -1)
fi
[ -n "$MODULE" ] || { echo "ERROR: can't tell which WiFi driver to load."; exit 1; }

# PCI address for this card — needed for bus reset
PCI_ADDR=$(lspci -k | grep -B1 "Kernel modules:.*${MODULE%%_*}" \
    | grep -oP '[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f]' | head -1)

unload_module() {
    for h in /sys/module/"$MODULE"/holders/*; do
        [ -e "$h" ] && rmmod "$(basename "$h")" 2>/dev/null || true
    done
    rmmod "$MODULE" 2>/dev/null || true
    sleep 1
}

pci_reset() {
    echo "==> PCI bus wedge (HW_REV=0xFFFFFFFF) — resetting $PCI_ADDR"
    grep -q "^$MODULE " /proc/modules && unload_module
    echo 1 > "/sys/bus/pci/devices/$PCI_ADDR/remove" 2>/dev/null || true
    sleep 1
    echo 1 > /sys/bus/pci/rescan
    sleep 2
}

# ── Step 1: unload if stuck (loaded but no interface) ─────────────────────────
if grep -q "^$MODULE " /proc/modules && ! ls -d /sys/class/net/*/wireless >/dev/null 2>&1; then
    echo "==> $MODULE loaded but no interface — unloading"
    unload_module
fi

# ── Step 2: first modprobe attempt ────────────────────────────────────────────
echo "==> Loading $MODULE"
modprobe "$MODULE"

# Give the driver a moment to initialize
sleep 2

# ── Step 3: if still no interface, check for PCI wedge and retry ──────────────
if ! ls -d /sys/class/net/*/wireless >/dev/null 2>&1; then
    if [ -n "$PCI_ADDR" ] && dmesg | tail -30 | grep -q "HW_REV=0xFFFFFFFF"; then
        pci_reset
        echo "==> Retrying modprobe after PCI reset"
        modprobe "$MODULE"
    fi
fi

# ── Step 4: wait for interface ────────────────────────────────────────────────
systemctl reset-failed "$SERVICE" 2>/dev/null || true
rfkill unblock wifi 2>/dev/null || true
command -v nmcli >/dev/null && nmcli radio wifi on

for _ in $(seq 10); do
    WDIR=$(ls -d /sys/class/net/*/wireless 2>/dev/null | head -1)
    [ -n "$WDIR" ] && break
    sleep 1
done

if [ -z "$WDIR" ]; then
    LOG=/home/rkraig/ubuntu-fixes/wifi-up-failure.txt
    {
        echo "=== wifi-up failure $(date) ==="
        echo "--- kernel wifi/pci messages ---"
        journalctl -b -k | grep -i -E 'iwlwifi|iwlmld|HW_REV|PCI issues' | tail -40
        echo "--- service status ---"
        systemctl status "$SERVICE" --no-pager 2>&1
        echo "--- rfkill ---"
        rfkill list 2>&1
        echo "--- lspci ---"
        lspci -k | grep -A3 -i 'network controller' 2>&1
    } > "$LOG" 2>&1
    chown rkraig:rkraig "$LOG" 2>/dev/null || true
    echo "ERROR: no WiFi interface after loading $MODULE."
    echo "       Logs saved to $LOG — show that file to Claude."
    exit 1
fi

IFACE=$(basename "$(dirname "$WDIR")")
echo "==> $IFACE is back"
command -v nmcli >/dev/null && nmcli -t -f DEVICE,STATE,CONNECTION device | grep "^$IFACE:"
exit 0
