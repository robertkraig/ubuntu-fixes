#!/bin/bash
# Exit 0 = applies/needs update, 1 = not applicable, 2 = already applied.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/deploy.sh"

IFACE=$(basename "$(dirname "$(ls -d /sys/class/net/*/wireless 2>/dev/null | head -1)")" 2>/dev/null)
[ -n "$IFACE" ] && [ "$IFACE" != "." ] || { echo "no wireless interface found"; exit 1; }

MODULE=$(basename "$(readlink -f "/sys/class/net/$IFACE/device/driver/module")" 2>/dev/null)
[ -n "$MODULE" ] || { echo "could not determine WiFi kernel module"; exit 1; }

HOLDERS=""
for h in /sys/module/"$MODULE"/holders/*; do
    [ -e "$h" ] && HOLDERS+="$(basename "$h") "
done

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DST="/etc/systemd/system/wifi-sleep-unload.service"

service_current=false
wifiup_current=false
deployed_and_current "$DIR/wifi-sleep-unload.service" "$DST" \
    "MODULE=$MODULE" "HOLDERS=$HOLDERS" && service_current=true
file_current "$DIR/wifi-up.sh" "/usr/local/bin/wifi-up" && wifiup_current=true

if $service_current && $wifiup_current; then
    echo "already applied: service current for $IFACE ($MODULE)"
    exit 2
fi

stale=()
$service_current || stale+=("service")
$wifiup_current  || stale+=("wifi-up")
[ -f "$DST" ] && echo "installed but stale: ${stale[*]} — will update" || \
    echo "WiFi interface $IFACE ($MODULE), not installed"
exit 0
