#!/bin/bash
# Args: $1=ACTUAL_USER $2=USER_HOME
# Installs the NVIDIA driver ubuntu-drivers recommends for this GPU, plus PRIME
# switching tools. Skips machines without an NVIDIA GPU.

lspci -nn | grep -E 'VGA|3D|Display' | grep -qi nvidia || { echo "  No NVIDIA GPU, skipping"; exit 0; }

DRIVER=$(ubuntu-drivers devices 2>/dev/null \
    | awk '/^driver *: nvidia-driver-[0-9]+ .*recommended/ {print $3; exit}')

if [ -z "$DRIVER" ]; then
    echo "  WARNING: ubuntu-drivers has no recommended NVIDIA driver for this GPU"
    exit 0
fi

PKGS=("$DRIVER" nvidia-prime nvidia-settings)
# Plasma tray widget for switching PRIME modes
dpkg -l plasma-desktop 2>/dev/null | grep -q '^ii' && PKGS+=(plasma-optimus)

echo "  GPU: $(ubuntu-drivers devices 2>/dev/null | awk -F': ' '/^model/ {print $2; exit}')"
echo "  Installing: ${PKGS[*]}"
apt-get install -y "${PKGS[@]}"
