#!/bin/bash
# Run as your regular user, not root.
set -e

DROPIN_DIR="$HOME/.config/systemd/user/plasma-powerdevil.service.d"

echo "==> Creating systemd user drop-in directory..."
mkdir -p "$DROPIN_DIR"

echo "==> Installing ordering drop-in..."
cp plasma-powerdevil-after-tlp-pd.conf "$DROPIN_DIR/after-tlp-pd.conf"

echo "==> Reloading systemd user daemon..."
systemctl --user daemon-reload

echo "==> Done. Power profile controls will appear in the Plasma battery widget on next login."
