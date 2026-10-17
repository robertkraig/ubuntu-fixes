#!/bin/bash
set -e

echo "==> Copying NVIDIA modprobe config..."
cp nvidia-graphics-drivers-kms.conf /etc/modprobe.d/nvidia-graphics-drivers-kms.conf

echo "==> Switching to Intel prime mode..."
prime-select intel

echo "==> Updating initramfs..."
update-initramfs -u

echo "==> Done. Reboot required."
echo "    After reboot, verify with: cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status"
echo "    Expected: suspended"
