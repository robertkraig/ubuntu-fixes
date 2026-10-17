#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.

gpus=$(lspci -nn | grep -E 'VGA|3D|Display')
echo "$gpus" | grep -qi nvidia || { echo "no NVIDIA GPU"; exit 1; }
echo "$gpus" | grep -qiE 'intel|amd|ati' || { echo "NVIDIA only, not a hybrid (Optimus/PRIME) system"; exit 1; }
modinfo nvidia >/dev/null 2>&1 || { echo "hybrid GPU, but the proprietary nvidia driver isn't installed"; exit 1; }

if grep -qs 'NVreg_DynamicPowerManagement=0x02' /etc/modprobe.d/*.conf \
    && [ "$(prime-select query 2>/dev/null)" = "intel" ]; then
    echo "already applied: dynamic power management on, prime-select intel"
    exit 2
fi

echo "hybrid GPU with nvidia driver $(modinfo -F version nvidia)"
exit 0
