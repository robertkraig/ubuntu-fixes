#!/bin/bash
set -e

if dpkg-query -W -f='${Status}' kdeconnect 2>/dev/null | grep -q 'install ok installed'; then
    echo "==> Removing KDE Connect..."
    apt-get purge -y kdeconnect
    apt-get autoremove -y
fi

# Removing the package doesn't stop the daemon already running in your session
if pkill -x kdeconnectd; then
    echo "==> Stopped running kdeconnectd"
fi

echo "==> Done. Reinstall with: sudo apt install kdeconnect"
