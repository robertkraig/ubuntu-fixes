# Fix: NVIDIA GPU Idle Power Draw

## Problem

On Optimus hybrid laptops, the NVIDIA GPU draws ~17W at idle under X11 because
Xorg keeps a persistent connection to it. Under Wayland this is much better, but
`NVreg_DynamicPowerManagement` must still be enabled for the GPU to fully suspend
when not in use.

Check GPU power state:
```bash
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
# should say: suspended
```

## Fix

1. Switch to Intel-only mode (NVIDIA only activates when an app requests it):
   ```bash
   sudo prime-select intel
   ```

2. Enable NVIDIA dynamic power management in modprobe config.

3. Use Wayland instead of X11 (Wayland allows proper GPU power gating).

## Install

```bash
sudo ./install.sh
```

Requires a reboot to take effect.

## Files

- `nvidia-graphics-drivers-kms.conf` — drop this in `/etc/modprobe.d/`
