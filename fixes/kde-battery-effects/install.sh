#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rc=0; reason=$("$DIR/applies.sh") || rc=$?
[ "$rc" -eq 1 ] && { echo "Skipping: $reason"; exit 0; }
[ "$rc" -eq 2 ] && { echo "Already applied: $reason"; exit 0; }

# Resolve real user even when run under sudo
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "==> Installing KDE battery effects toggle for $REAL_USER..."

# Install the main script
install -Dm755 "$DIR/kde-power-effects.sh" "$REAL_HOME/.local/bin/kde-power-effects.sh"
chown -R "$REAL_USER:" "$REAL_HOME/.local/bin/kde-power-effects.sh"

# Convenience wrappers for manual use
cat > "$REAL_HOME/.local/bin/kde-battery-effects-off.sh" << EOF
#!/bin/bash
ON_AC=0 $REAL_HOME/.local/bin/kde-power-effects.sh
EOF

cat > "$REAL_HOME/.local/bin/kde-battery-effects-on.sh" << EOF
#!/bin/bash
ON_AC=1 $REAL_HOME/.local/bin/kde-power-effects.sh
EOF

chmod +x "$REAL_HOME/.local/bin/kde-battery-effects-off.sh" \
         "$REAL_HOME/.local/bin/kde-battery-effects-on.sh"
chown "$REAL_USER:" "$REAL_HOME/.local/bin/kde-battery-effects-off.sh" \
                    "$REAL_HOME/.local/bin/kde-battery-effects-on.sh"

mkdir -p "$REAL_HOME/.config/systemd/user"
chown -R "$REAL_USER:" "$REAL_HOME/.config/systemd"
cat > "$REAL_HOME/.config/systemd/user/kde-power-effects.service" << EOF
[Unit]
Description=Apply KDE compositor effects based on power state
After=plasma-kwin_wayland.service graphical-session.target
PartOf=graphical-session.target

[Service]
Type=oneshot
ExecStart=$REAL_HOME/.local/bin/kde-power-effects.sh
RemainAfterExit=no

[Install]
WantedBy=graphical-session.target
EOF

# udev rule — fires on AC plug/unplug, runs script as the logged-in user
sudo tee /etc/udev/rules.d/99-kde-power-effects.rules > /dev/null << EOF
SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="/usr/bin/systemd-run --user --machine=$(whoami)@ --no-ask-password -u kde-power-effects-udev $HOME/.local/bin/kde-power-effects.sh"
SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/bin/systemd-run --user --machine=$(whoami)@ --no-ask-password -u kde-power-effects-udev $HOME/.local/bin/kde-power-effects.sh"
EOF

udevadm control --reload-rules

sudo -u "$REAL_USER" systemctl --user daemon-reload
sudo -u "$REAL_USER" systemctl --user enable --now kde-power-effects.service

echo ""
echo "==> Done."
echo "    Login trigger: kde-power-effects.service"
echo "    AC trigger:    /etc/udev/rules.d/99-kde-power-effects.rules"
echo "    Manual off:    ~/.local/bin/kde-battery-effects-off.sh"
echo "    Manual on:     ~/.local/bin/kde-battery-effects-on.sh"
