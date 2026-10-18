#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/deploy.sh"

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
BIN="$REAL_HOME/.local/bin"
UNIT_DIR="$REAL_HOME/.config/systemd/user"

rc=0; reason=$(sudo -u "$REAL_USER" HOME="$REAL_HOME" "$DIR/applies.sh") || rc=$?
[ "$rc" -eq 1 ] && { echo "Skipping: $reason"; exit 0; }
[ "$rc" -eq 2 ] && { echo "Already applied: $reason"; exit 0; }

user_systemctl() { systemctl --machine="$REAL_USER@.host" --user "$@"; }

echo "==> Installing KDE battery effects toggle for $REAL_USER..."

install -d -m 755 -o "$REAL_USER" -g "$REAL_USER" "$BIN"
deploy_file "$DIR/kde-power-effects.sh" "$BIN/kde-power-effects.sh" "$REAL_USER" 755

for mode in off:0 on:1; do
    f="$BIN/kde-battery-effects-${mode%%:*}.sh"
    printf '#!/bin/bash\nON_AC=%s %s/kde-power-effects.sh\n' "${mode##*:}" "$BIN" > "$f"
    chmod 755 "$f"
    chown "$REAL_USER:$REAL_USER" "$f"
done

install -d -m 755 -o "$REAL_USER" -g "$REAL_USER" "$UNIT_DIR"
deploy_template "$DIR/kde-power-effects.service" "$UNIT_DIR/kde-power-effects.service" "$REAL_USER" \
    "BIN=$BIN"

deploy_template "$DIR/99-kde-power-effects.rules" "/etc/udev/rules.d/99-kde-power-effects.rules" "" \
    "USER=$REAL_USER" "BIN=$BIN"
udevadm control --reload-rules

user_systemctl daemon-reload
user_systemctl enable --now kde-power-effects.service

echo ""
echo "==> Done."
echo "    Login trigger: kde-power-effects.service"
echo "    AC trigger:    /etc/udev/rules.d/99-kde-power-effects.rules"
echo "    Manual off:    ~/.local/bin/kde-battery-effects-off.sh"
echo "    Manual on:     ~/.local/bin/kde-battery-effects-on.sh"
