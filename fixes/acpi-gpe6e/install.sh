#!/bin/bash
set -e

GRUB_FILE="/etc/default/grub"
PARAM="acpi_mask_gpe=0x6E"

if grep -q "$PARAM" "$GRUB_FILE"; then
    echo "Already applied: $PARAM found in $GRUB_FILE"
    exit 0
fi

# Add param to GRUB_CMDLINE_LINUX_DEFAULT
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 $PARAM\"/" "$GRUB_FILE"

echo "Updated $GRUB_FILE"
update-grub
echo "Done. Reboot to apply."
