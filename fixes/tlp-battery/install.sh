#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DROPIN="/etc/tlp.d/00-ubuntu-fixes.conf"
CHOICES_FILE="/sys/firmware/acpi/platform_profile_choices"

# First choice the firmware supports, from a preference list
pick_profile() {
    local choices
    choices=$(cat "$CHOICES_FILE" 2>/dev/null)
    for want in "$@"; do
        [[ " $choices " == *" $want "* ]] && { echo "$want"; return; }
    done
}

if ! apt-cache policy 2>/dev/null | grep -q "linrunner/tlp"; then
    echo "==> Adding linrunner TLP PPA..."
    add-apt-repository -y ppa:linrunner/tlp
    apt update
fi

echo "==> Installing TLP + tlp-pd..."
apt install -y tlp tlp-rdw tlp-pd

echo "==> Stopping power-profiles-daemon if running..."
systemctl disable --now power-profiles-daemon 2>/dev/null || true

echo "==> Picking platform profiles..."
pp=""
if [ -f "$CHOICES_FILE" ]; then
    echo "    firmware offers: $(cat "$CHOICES_FILE")"
    ac=$(pick_profile balanced performance)
    bat=$(pick_profile low-power quiet cool balanced)
    sav=$(pick_profile low-power quiet cool)
    [ -n "$ac" ]  && pp+="PLATFORM_PROFILE_ON_AC=$ac"$'\n'
    [ -n "$bat" ] && pp+="PLATFORM_PROFILE_ON_BAT=$bat"$'\n'
    [ -n "$sav" ] && pp+="PLATFORM_PROFILE_ON_SAV=$sav"$'\n'
else
    echo "    no ACPI platform profile on this machine, skipping"
fi

echo "==> Writing $DROPIN..."
awk -v pp="$pp" '$0 == "{{PLATFORM_PROFILE}}" { printf "%s", pp; next } { print }' \
    "$DIR/tlp.conf" > "$DROPIN"

# /etc/tlp.conf is read last and overrides every drop-in.
# Comment out all active lines so the drop-in takes full effect.
# TLP_DEFAULT_MODE=BAT is silently dropped (forces battery policies on AC).
# Everything else is migrated to /etc/tlp.d/50-local.conf so nothing is lost.
if grep -qvE '^\s*(#|$)' /etc/tlp.conf 2>/dev/null; then
    active=$(grep -vE '^\s*(#|$)' /etc/tlp.conf)
    migrate=$(echo "$active" | grep -v '^TLP_DEFAULT_MODE=')
    if [ -n "$migrate" ]; then
        echo "==> Migrating active /etc/tlp.conf settings to /etc/tlp.d/50-local.conf..."
        {
            echo "# Migrated from /etc/tlp.conf by ubuntu-fixes tlp-battery install"
            echo "$migrate"
        } >> /etc/tlp.d/50-local.conf
        echo "    Migrated:"
        echo "$migrate" | sed 's/^/      /'
    fi
    echo "==> Commenting out all active lines in /etc/tlp.conf (drop-in takes over)..."
    sed -i 's/^\([^#].*\)$/# \1/' /etc/tlp.conf
fi

echo "==> Enabling and starting TLP services..."
systemctl enable tlp tlp-pd
systemctl restart tlp tlp-pd

echo "==> Done. Check with: tlpctl list"
echo "    Charge thresholds: start=20% stop=80% — use 'sudo tlp fullcharge' before trips."
