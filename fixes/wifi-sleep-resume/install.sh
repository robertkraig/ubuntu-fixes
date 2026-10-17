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
# rmmod, not modprobe -r: Ubuntu's /etc/modprobe.d/iwlwifi.conf has a "remove iwlwifi"
# rule that unloads iwlmvm+iwlwifi itself, so "modprobe -r iwlmvm iwlwifi" fails on the
# second name. Start must always succeed, or systemd never runs ExecStop on resume.
ExecStart=/bin/sh -c 'for m in $HOLDERS$MODULE; do grep -q "^\$m " /proc/modules && /usr/sbin/rmmod \$m; done; exit 0'
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
systemctl reset-failed wifi-sleep-unload.service 2>/dev/null || true
systemctl enable wifi-sleep-unload.service

echo "==> Done. Test: suspend, resume, and WiFi should reconnect within a few seconds."
