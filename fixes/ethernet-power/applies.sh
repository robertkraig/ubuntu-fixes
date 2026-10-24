#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/deploy.sh"

ls -d /sys/class/power_supply/*/ 2>/dev/null | while read -r ps; do cat "$ps/type"; done | grep -qx Battery \
    || { echo "no battery (not a laptop)"; exit 1; }

# Need at least one wired ethernet interface
found=0
for iface in $(ls /sys/class/net/ 2>/dev/null); do
    [ "$iface" = "lo" ] && continue
    [ -d "/sys/class/net/$iface/wireless" ] && continue
    [ -d "/sys/class/net/$iface/bridge" ] && continue
    readlink "/sys/class/net/$iface" 2>/dev/null | grep -qE 'virtual|veth|docker|br-' && continue
    found=1; break
done
[ "$found" -eq 1 ] || { echo "no wired ethernet interface found"; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
stale=()
file_current "$DIR/ethernet-power.sh"       /usr/local/bin/ethernet-power                || stale+=("script")
file_current "$DIR/99-ethernet-power.rules" /etc/udev/rules.d/99-ethernet-power.rules    || stale+=("udev-rule")
file_current "$DIR/ethernet-aliases.zsh"    /usr/local/share/ethernet-aliases.zsh        || stale+=("aliases")

[ ${#stale[@]} -eq 0 ] && { echo "already applied"; exit 2; }
[ -f /usr/local/bin/ethernet-power ] && echo "installed but stale: ${stale[*]}" || echo "wired ethernet found"
exit 0
