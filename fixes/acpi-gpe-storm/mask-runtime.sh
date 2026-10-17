#!/bin/bash
# Masks any storming GPE immediately without a reboot. Does not persist.
# Note: older kernels use "disable", kernel 7.0+ requires "mask"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

storms=$("$DIR/detect-storm.sh" 3 100)
[ -z "$storms" ] && { echo "No GPE storm detected."; exit 0; }

while read -r gpe rate; do
    f="/sys/firmware/acpi/interrupts/gpe$gpe"
    { echo mask > "$f" && echo "gpe$gpe masked (${rate}/s)"; } 2>/dev/null || \
    { echo disable > "$f" && echo "gpe$gpe disabled (${rate}/s)"; }
    cat "$f"
done <<< "$storms"
