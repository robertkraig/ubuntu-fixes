#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/deploy.sh"

rc=0; reason=$("$DIR/applies.sh") || rc=$?
[ "$rc" -eq 1 ] && { echo "Skipping: $reason"; exit 0; }
[ "$rc" -eq 2 ] && { echo "Already applied: $reason"; exit 0; }

IFACE=$(basename "$(dirname "$(ls -d /sys/class/net/*/wireless 2>/dev/null | head -1)")")
MODULE=$(basename "$(readlink -f "/sys/class/net/$IFACE/device/driver/module")")
HOLDERS=""
for h in /sys/module/"$MODULE"/holders/*; do
    [ -e "$h" ] && HOLDERS+="$(basename "$h") "
done

echo "==> WiFi: $IFACE, driver: $MODULE${HOLDERS:+ (holders: $HOLDERS)}"

SERVICE="/etc/systemd/system/wifi-sleep-unload.service"
deploy_template "$DIR/wifi-sleep-unload.service" "$SERVICE" "" \
    "MODULE=$MODULE" "HOLDERS=$HOLDERS"
echo "==> Installed $SERVICE"

if [ -f /usr/lib/systemd/system-sleep/wifi-cycle ]; then
    rm /usr/lib/systemd/system-sleep/wifi-cycle
    echo "==> Removed old wifi-cycle hook"
fi

# Manual recovery command, in case WiFi is ever still off after resume
install -m 755 "$DIR/wifi-up.sh" /usr/local/bin/wifi-up
echo "==> Installed /usr/local/bin/wifi-up (run it if WiFi is ever off after resume)"

systemctl daemon-reload
systemctl reset-failed wifi-sleep-unload.service 2>/dev/null || true
systemctl enable wifi-sleep-unload.service

echo "==> Done. Test: suspend, resume — WiFi should reconnect within a few seconds."
