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
    grep -q 'START_CHARGE_THRESH_BAT0=50' /etc/tlp.d/00-ubuntu-fixes.conf 2>/dev/null || stale+=("charge thresholds missing")
    for f in /etc/tlp.d/*.conf; do
        [[ "$f" > /etc/tlp.d/00-ubuntu-fixes.conf ]] || continue
        while read -r key; do
            grep -q "^$key" "$f" && { stale+=("$(basename "$f") overrides ${key%=}"); break; }
        done < <(grep -oE '^[A-Z0-9_]+=' /etc/tlp.d/00-ubuntu-fixes.conf | sort -u)
    done
    ls /sys/class/drm/card*/gt_RP0_freq_mhz >/dev/null 2>&1 \
        && ! grep -q '^INTEL_GPU_MAX_FREQ_ON_AC=' /etc/tlp.d/00-ubuntu-fixes.conf \
        && stale+=("Intel GPU clock limits missing")
    [ ${#stale[@]} -gt 0 ] && { echo "installed but stale: $(printf "%s; " "${stale[@]}" | sed "s/; $//")"; exit 0; }
    echo "already installed: TLP $(dpkg-query -W -f='${Version}' tlp) + tlp-pd, $driver"
    exit 2
fi

echo "laptop with $driver"
exit 0
