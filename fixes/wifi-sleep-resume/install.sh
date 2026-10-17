#!/bin/bash
set -e

SERVICE="/etc/systemd/system/wifi-sleep-unload.service"

# Wireless interface -> its kernel driver module -> modules that depend on it
IFACE=$(basename "$(dirname "$(ls -d /sys/class/net/*/wireless 2>/dev/null | head -1)")")
[ -n "$IFACE" ] && [ "$IFACE" != "." ] || { echo "ERROR: No wireless interface found."; exit 1; }

MODULE=$(basename "$(readlink -f "/sys/class/net/$IFACE/device/driver/module")")
HOLDERS=""
for h in /sys/module/"$MODULE"/holders/*; do
    [ -e "$h" ] && HOLDERS+="$(basename "$h") "
done

echo "==> WiFi: $IFACE, driver $MODULE${HOLDERS:+ (used by: $HOLDERS)}"

cat > "$SERVICE" <<EOF
[Unit]
Description=Unload $MODULE before sleep, reload after resume (WiFi resume hang workaround)
Before=sleep.target
StopWhenUnneeded=yes

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/modprobe -r $HOLDERS$MODULE
ExecStop=/usr/sbin/modprobe $MODULE

[Install]
WantedBy=sleep.target
EOF
echo "==> Installed $SERVICE"

# Older version of this fix: an interface down/up hook, battery only
if [ -f /usr/lib/systemd/system-sleep/wifi-cycle ]; then
    rm /usr/lib/systemd/system-sleep/wifi-cycle
    echo "==> Removed old /usr/lib/systemd/system-sleep/wifi-cycle hook"
fi

systemctl daemon-reload
systemctl enable wifi-sleep-unload.service

echo "==> Done. Test: suspend, resume, and WiFi should reconnect within a few seconds."
