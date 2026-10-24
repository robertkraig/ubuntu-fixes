#!/bin/bash
# Called by the systemd user service on login and by udev (via systemd-run --user) on AC change.
# On battery: remember which of EFFECTS are loaded, then unload them.
# On AC: reload exactly the effects that were loaded before, so your KWin settings are kept.
# Set ON_AC=0 or ON_AC=1 to force a state (used by the kde-battery-effects-off/on wrappers).

# Log everything to the journal: journalctl -t ubuntu-fixes/kde-power-effects
exec > >(logger -t ubuntu-fixes/kde-power-effects) 2>&1

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/kde-power-effects.saved"
EFFECTS=(wobblywindows scale squash translucency blur backgroundcontrast fadingpopups slide zoom kwin4_effect_magiclamp)

# Charger name varies (AC, AC0, ADP1, ACAD), so find the "Mains" supply
if [ -z "$ON_AC" ]; then
    for ps in /sys/class/power_supply/*; do
        [ "$(cat "$ps/type" 2>/dev/null)" = "Mains" ] && { ON_AC=$(cat "$ps/online"); break; }
    done
fi
ON_AC=${ON_AC:-1}

effect() { qdbus6 org.kde.KWin /Effects "$@" 2>/dev/null; }

if [ "$ON_AC" = "1" ]; then
    [ -f "$STATE" ] || { echo "on AC, nothing saved to restore"; exit 0; }
    echo "on AC, reloading: $(tr '\n' ' ' < "$STATE")"
    while read -r e; do
        [ -n "$e" ] && effect loadEffect "$e" >/dev/null
    done < "$STATE"
    rm -f "$STATE"
else
    mkdir -p "$(dirname "$STATE")"
    # Keep anything already saved (e.g. unplugged twice without plugging in)
    saved=$(cat "$STATE" 2>/dev/null)
    for e in "${EFFECTS[@]}"; do
        [ "$(effect isEffectLoaded "$e")" = "true" ] && saved+=$'\n'"$e"
    done
    echo "$saved" | sed '/^$/d' | sort -u > "$STATE"
    echo "on battery, unloading: $(tr '\n' ' ' < "$STATE")"
    while read -r e; do
        effect unloadEffect "$e"
    done < "$STATE"
fi
