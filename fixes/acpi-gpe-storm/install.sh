#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRUB_FILE="/etc/default/grub"

echo "==> Sampling ACPI GPEs for 5 seconds..."
storms=$("$DIR/detect-storm.sh" 5 100)

if [ -z "$storms" ]; then
    echo "No GPE storm detected. Nothing to do."
    exit 0
fi

changed=0
while read -r gpe rate; do
    param="acpi_mask_gpe=0x$gpe"
    echo "==> gpe$gpe firing ${rate}/s"

    # Mask now (kernel 7.0+ needs "mask"; older kernels accept "disable")
    echo mask > "/sys/firmware/acpi/interrupts/gpe$gpe" 2>/dev/null \
        || echo disable > "/sys/firmware/acpi/interrupts/gpe$gpe"
    echo "    masked for this boot"

    if grep -q "$param" "$GRUB_FILE"; then
        echo "    already in $GRUB_FILE"
    else
        sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 $param\"/" "$GRUB_FILE"
        echo "    added $param to $GRUB_FILE"
        changed=1
    fi
done <<< "$storms"

if [ "$changed" -eq 1 ]; then
    update-grub
    echo "==> Done. Masked now, and permanently from next boot."
else
    echo "==> Done."
fi
