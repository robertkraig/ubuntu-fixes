---
name: system-setup
description: Linux system configuration and power management setup
metadata:
  node_type: memory
  type: project
  originSessionId: 9d0fe937-b21e-4353-b280-89282212c3c8
  modified: 2026-10-17T05:23:27.707Z
---

Ubuntu 26.04 LTS ("Resolute Raccoon"), kernel 7.0, KDE Plasma 6.6.6 on Wayland.

**Why:** Upgraded from 24.04 on 2026-10-15. Wayland is now default.

**Power management:**
- TLP 1.10.2 (from linrunner PPA `ppa:linrunner/tlp`) + `tlp-pd` daemon active
  - `tlp-pd.service` exposes `net.hadess.PowerProfiles` D-Bus interface for Plasma UI integration
  - Config at `/etc/tlp.conf` (kept during upgrade)
  - `CPU_SCALING_GOVERNOR_ON_AC=powersave` (changed from performance to reduce idle heat)
  - `CPU_MAX_PERF_ON_BAT=100`, `CPU_BOOST_ON_BAT=1` (relaxed from aggressive 50%/2GHz cap)
  - `CPU_ENERGY_PERF_POLICY_ON_BAT=power` (NOT power-saver — that's a ppd value, invalid in TLP)
- Lid close: acpid handler `/etc/acpi/lid.sh` runs `lid-closed` (tlp bat, low platform profile, 15W RAPL cap via MSR or MMIO zone) / `lid-open` (restore)
- NVIDIA: `/etc/modprobe.d/nvidia-graphics-drivers-kms.conf` has `NVreg_DynamicPowerManagement=0x02`
- GRUB: `acpi_mask_gpe=0x6E` added to mask runaway gpe6E interrupt (~1500/sec was draining battery); `update-grub` run — needs reboot to apply
- Config backups at `~/.config-backup-pre-2604/`

**NVIDIA/GPU:**
- `prime-select intel` mode — NVIDIA module unloaded, GPU not drawing power
- On Wayland, GPU properly power-gates between uses (unlike X11)
- `plasma-optimus` installed for GUI switching

**How to apply:** When helping with power/thermal issues, check TLP status with `sudo tlp-stat -s` and GPU state with `/bin/cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status`. Note: `cat` is aliased to `bat` in user's zsh.
