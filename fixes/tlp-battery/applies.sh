#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.

ls /sys/class/power_supply/BAT* >/dev/null 2>&1 || { echo "no battery (not a laptop)"; exit 1; }

driver=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null)
case "$driver" in
    intel_pstate|amd-pstate*) ;;
    *) echo "CPU driver '$driver' has no EPP support; config is tuned for intel_pstate/amd-pstate"; exit 1 ;;
esac

if [ -f /etc/tlp.d/00-ubuntu-fixes.conf ] && dpkg -l tlp-pd 2>/dev/null | grep -q '^ii'; then
    stale=()
    grep -qvE '^\s*(#|$)' /etc/tlp.conf 2>/dev/null && stale+=("active settings in /etc/tlp.conf override drop-in")
    grep -q 'START_CHARGE_THRESH_BAT0=20' /etc/tlp.d/00-ubuntu-fixes.conf 2>/dev/null || stale+=("charge thresholds missing")
    [ ${#stale[@]} -gt 0 ] && { echo "installed but stale: ${stale[*]}"; exit 0; }
    echo "already installed: TLP $(dpkg-query -W -f='${Version}' tlp) + tlp-pd, $driver"
    exit 2
fi

echo "laptop with $driver"
exit 0
