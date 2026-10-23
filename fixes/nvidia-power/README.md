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

3. In intel mode, remove the GPU's HDMI audio function (and USB-C/UCSI functions on
   Turing+) at boot with a udev rule. The kernel enables the GPU's hidden audio function
   and `snd_hda_intel` binds it; while it's awake the whole GPU and its PCIe port stay
   powered even though the NVIDIA driver isn't loaded. Seen on a Precision 7510
   (Quadro M2000M): 20.4W → 13.8W. The rule only acts while
   `/lib/modprobe.d/blacklist-nvidia.conf` exists, i.e. in `prime-select intel` mode.

   Check: `ls /sys/bus/pci/devices/ | grep 01:00` should list only `01:00.0`.

4. Use Wayland instead of X11 (Wayland allows proper GPU power gating).

## Install

```bash
sudo ./install.sh
```

Requires a reboot to take effect.

## Files

- `install.sh` — writes `/etc/modprobe.d/nvidia-graphics-drivers-kms.conf` (DPM only on
  Turing+) and `/etc/udev/rules.d/80-ubuntu-fixes-nvidia-intel.rules`, selects intel mode
- `applies.sh` — used by `fixes.sh` to decide whether this fix applies
