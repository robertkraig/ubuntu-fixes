#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.

systemctl --user cat plasma-powerdevil.service >/dev/null 2>&1 || { echo "not KDE Plasma"; exit 1; }
dpkg -l tlp-pd 2>/dev/null | grep -q '^ii' || { echo "tlp-pd not installed"; exit 1; }
[ -f "$HOME/.config/systemd/user/plasma-powerdevil.service.d/after-tlp-pd.conf" ] \
    && { echo "already installed"; exit 2; }

echo "Plasma + tlp-pd"
exit 0
