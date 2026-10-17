#!/bin/bash
# Masks gpe6E immediately without a reboot. Does not persist.
# Note: older kernels use "disable", kernel 7.0+ requires "mask"
echo "mask" > /sys/firmware/acpi/interrupts/gpe6E && echo "gpe6E masked" || \
echo "disable" > /sys/firmware/acpi/interrupts/gpe6E && echo "gpe6E disabled"
cat /sys/firmware/acpi/interrupts/gpe6E
