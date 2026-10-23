#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.

command -v plasmashell >/dev/null 2>&1 || { echo "KDE Plasma not installed"; exit 1; }

if dpkg-query -W -f='${Status}' kdeconnect 2>/dev/null | grep -q 'install ok installed'; then
    echo "KDE Connect installed (kdeconnectd wakes the CPU ~60x/s, ~1W)"
    exit 0
fi

if pgrep -x kdeconnectd >/dev/null; then
    echo "package removed, but kdeconnectd is still running"
    exit 0
fi

echo "already applied: KDE Connect not installed"
exit 2
