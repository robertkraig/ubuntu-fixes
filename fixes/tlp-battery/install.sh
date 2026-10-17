#!/bin/bash
set -e

echo "==> Adding linrunner TLP PPA..."
add-apt-repository -y ppa:linrunner/tlp
apt update

echo "==> Installing TLP 1.10.2 + tlp-pd..."
apt install -y tlp tlp-pd

echo "==> Stopping power-profiles-daemon if running..."
systemctl disable --now power-profiles-daemon 2>/dev/null || true

echo "==> Applying TLP config..."
cp tlp.conf /etc/tlp.conf

echo "==> Enabling and starting TLP services..."
systemctl enable tlp tlp-pd
systemctl restart tlp tlp-pd

echo "==> Installing powerdevil systemd ordering fix..."
mkdir -p /run/systemd/user/plasma-powerdevil.service.d
# Drop-in goes to the user's config, not /run — handled separately
echo "NOTE: Run install-powerdevil-fix.sh as your user (not root) for the Plasma UI fix."

echo "==> Done. Run 'sudo tlp bat' to apply battery profile now."
