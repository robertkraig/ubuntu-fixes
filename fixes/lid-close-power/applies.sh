#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.

ls /proc/acpi/button/lid/*/state >/dev/null 2>&1 || { echo "no laptop lid"; exit 1; }
command -v tlp >/dev/null || { echo "needs TLP (run tlp-battery first)"; exit 1; }
[ -f /etc/udev/rules.d/99-lid-tlp.rules ] && { echo "already installed"; exit 2; }

echo "laptop lid + TLP"
exit 0
