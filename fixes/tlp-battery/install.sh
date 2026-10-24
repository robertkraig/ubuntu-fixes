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
    ac=$(pick_profile performance balanced)
    bat=$(pick_profile low-power quiet cool balanced)
    sav=$(pick_profile low-power quiet cool)
    [ -n "$ac" ]  && pp+="PLATFORM_PROFILE_ON_AC=$ac"$'\n'
    [ -n "$bat" ] && pp+="PLATFORM_PROFILE_ON_BAT=$bat"$'\n'
    [ -n "$sav" ] && pp+="PLATFORM_PROFILE_ON_SAV=$sav"$'\n'
else
    echo "    no ACPI platform profile on this machine, skipping"
fi

echo "==> Reading Intel GPU clock range..."
gpu=""
rp0=$(cat /sys/class/drm/card*/gt_RP0_freq_mhz 2>/dev/null | head -1)
rpn=$(cat /sys/class/drm/card*/gt_RPn_freq_mhz 2>/dev/null | head -1)
if [ -n "$rp0" ] && [ -n "$rpn" ]; then
    # Power-saver: two thirds of max, rounded down to 50 MHz
    sav=$(( rp0 * 2 / 3 / 50 * 50 )); [ "$sav" -lt "$rpn" ] && sav=$rpn
    echo "    GPU ${rpn}-${rp0} MHz, power-saver max ${sav} MHz"
    for mode in AC BAT; do
        gpu+="INTEL_GPU_MIN_FREQ_ON_$mode=$rpn"$'\n'"INTEL_GPU_MAX_FREQ_ON_$mode=$rp0"$'\n'"INTEL_GPU_BOOST_FREQ_ON_$mode=$rp0"$'\n'
    done
    gpu+="INTEL_GPU_MIN_FREQ_ON_SAV=$rpn"$'\n'"INTEL_GPU_MAX_FREQ_ON_SAV=$sav"$'\n'"INTEL_GPU_BOOST_FREQ_ON_SAV=$sav"$'\n'
else
    echo "    no i915 GPU clock controls, skipping"
fi

echo "==> Writing $DROPIN..."
awk -v pp="$pp" -v gpu="$gpu" '
    $0 == "{{PLATFORM_PROFILE}}" { printf "%s", pp; next }
    $0 == "{{INTEL_GPU_FREQ}}"   { printf "%s", gpu; next }
    { print }' "$DIR/tlp.conf" > "$DROPIN"

# Drop-ins are read in name order and later ones win. Comment out any setting
# a later drop-in (hand-tuned or from another tool) has for a key we own.
for f in /etc/tlp.d/*.conf; do
    [[ "$f" > "$DROPIN" ]] || continue
    overridden=$(grep -oE '^[A-Z0-9_]+=' "$DROPIN" | sort -u | while read -r key; do
        grep -q "^$key" "$f" && echo "${key%=}"
    done)
    [ -z "$overridden" ] && continue
    echo "==> Commenting out settings in $f that override $DROPIN:"
    for key in $overridden; do
        sed -i "s/^$key=/# overridden by ubuntu-fixes: $key=/" "$f"
        echo "      $key"
    done
done

# /etc/tlp.conf is read last and overrides every drop-in.
# Comment out all active lines so the drop-in takes full effect.
# TLP_DEFAULT_MODE=BAT is silently dropped (forces battery policies on AC).
# Everything else is migrated to /etc/tlp.d/50-local.conf so nothing is lost.
if grep -qvE '^\s*(#|$)' /etc/tlp.conf 2>/dev/null; then
    active=$(grep -vE '^\s*(#|$)' /etc/tlp.conf)
    # Drop settings the drop-in already owns — migrating them creates conflicts
    migrate=$(echo "$active" | grep -vE '^(TLP_DEFAULT_MODE=|PLATFORM_PROFILE_ON_)')
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
echo "    Charge thresholds: start=50% stop=80% — use 'sudo tlp fullcharge' before trips."
