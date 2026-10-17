#!/bin/bash
# Called by systemd user service on login and by udev on AC change.
# Reads current power state and applies/removes KWin effects accordingly.

DBUS_SESSION=$(cat /run/user/$(id -u)/dbus-session 2>/dev/null || \
    grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u "$USER" kwin_wayland | head -1)/environ 2>/dev/null | tr '\0' '\n' | grep DBUS_SESSION_BUS_ADDRESS | cut -d= -f2-)

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-$DBUS_SESSION}"

ON_AC=$(cat /sys/class/power_supply/AC/online 2>/dev/null || \
        cat /sys/class/power_supply/AC0/online 2>/dev/null || echo 1)

kwin_effects() {
    local action="$1"; shift
    for effect in "$@"; do
        qdbus6 org.kde.KWin /Effects "${action}Effect" "$effect" 2>/dev/null || true
    done
}

EFFECTS=(wobblywindows scale squash translucency blur backgroundcontrast fadingpopups slide zoom kwin4_effect_magiclamp)

if [ "$ON_AC" = "1" ]; then
    kwin_effects load "${EFFECTS[@]}"
else
    kwin_effects unload "${EFFECTS[@]}"
fi
