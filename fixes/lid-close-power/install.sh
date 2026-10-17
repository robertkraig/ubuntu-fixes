#!/bin/bash
set -e

echo "==> Installing lid close udev rule..."
cp 99-lid-tlp.rules /etc/udev/rules.d/99-lid-tlp.rules

echo "==> Reloading udev rules..."
udevadm control --reload-rules

echo "==> Done. No reboot required."
echo "    Close the lid to test — CPU should drop to battery profile."
