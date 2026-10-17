#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[ -d /sys/firmware/acpi/interrupts ] || { echo "no ACPI GPEs (not an ACPI x86 system)"; exit 1; }

storms=$("$DIR/detect-storm.sh" 3 100)
if [ -n "$storms" ]; then
    echo "GPE storm: $(echo "$storms" | awk '{printf "gpe%s (%s/s) ", $1, $2}')"
    exit 0
fi

masked=$(grep -o 'acpi_mask_gpe=[^ ]*' /proc/cmdline | tr '\n' ' ')
[ -n "$masked" ] && { echo "already masked at boot: $masked"; exit 2; }

echo "no GPE storm detected"
exit 1
