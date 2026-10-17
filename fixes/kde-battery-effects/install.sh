#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve the real user even when run under sudo ($HOME and whoami are root's here)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
BIN="$REAL_HOME/.local/bin"
UNIT_DIR="$REAL_HOME/.config/systemd/user"

rc=0; reason=$(sudo -u "$REAL_USER" HOME="$REAL_HOME" "$DIR/applies.sh") || rc=$?
[ "$rc" -eq 1 ] && { echo "Skipping: $reason"; exit 0; }
[ "$rc" -eq 2 ] && { echo "Already applied: $reason"; exit 0; }

# systemctl --user for the real user, from root
user_systemctl() { systemctl --machine="$REAL_USER@.host" --user "$@"; }

echo "==> Installing KDE battery effects toggle for $REAL_USER..."

install -Dm755 -o "$REAL_USER" -g "$REAL_USER" "$DIR/kde-power-effects.sh" "$BIN/kde-power-effects.sh"

# Convenience wrappers for manual use
for mode in off:0 on:1; do
    f="$BIN/kde-battery-effects-${mode%%:*}.sh"
    printf '#!/bin/bash\nON_AC=%s %s/kde-power-effects.sh\n' "${mode##*:}" "$BIN" > "$f"
    chmod 755 "$f"
    chown "$REAL_USER:$REAL_USER" "$f"
done

install -d -o "$REAL_USER" -g "$REAL_USER" "$UNIT_DIR"
cat > "$UNIT_DIR/kde-power-effects.service" << EOF
[Unit]
Description=Apply KDE compositor effects based on power state
After=plasma-kwin_wayland.service graphical-session.target
PartOf=graphical-session.target

[Service]
Type=oneshot
ExecStart=$BIN/kde-power-effects.sh
RemainAfterExit=no

[Install]
WantedBy=graphical-session.target
EOF
chown "$REAL_USER:$REAL_USER" "$UNIT_DIR/kde-power-effects.service"

# udev rule — fires on charger plug/unplug, runs the script in the user's session
cat > /etc/udev/rules.d/99-kde-power-effects.rules << EOF
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ACTION=="change", RUN+="/usr/bin/systemd-run --user --machine=$REAL_USER@ --no-ask-password --collect $BIN/kde-power-effects.sh"
EOF
udevadm control --reload-rules

user_systemctl daemon-reload
user_systemctl enable --now kde-power-effects.service

echo ""
echo "==> Done."
echo "    Login trigger: kde-power-effects.service"
echo "    AC trigger:    /etc/udev/rules.d/99-kde-power-effects.rules"
echo "    Manual off:    ~/.local/bin/kde-battery-effects-off.sh"
echo "    Manual on:     ~/.local/bin/kde-battery-effects-on.sh"
