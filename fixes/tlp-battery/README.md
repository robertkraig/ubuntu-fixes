# Fix: TLP Battery Optimization + Plasma UI Integration

## Problem

Ubuntu ships `power-profiles-daemon` as the default power manager. TLP 1.10.2
with `tlp-pd` provides much more granular battery control and integrates with
the KDE Plasma battery widget via D-Bus.

Stock Ubuntu TLP config also has overly aggressive CPU caps that make Chrome
and other apps feel sluggish on battery.

## What this does

- Installs TLP 1.10.2 from the linrunner PPA
- Installs `tlp-pd` (TLP Power Daemon) which exposes `net.hadess.PowerProfiles`
  D-Bus interface so Plasma shows power profile controls in the battery widget
- Applies a tuned `tlp.conf`:
  - CPU governor: `powersave` on both AC and battery (uses HWP/EPP instead)
  - EPP: `balance_performance` on AC, `power` on battery
  - CPU boost and max perf: **enabled** on battery (lets EPP handle efficiency)
  - Bluetooth: auto-disabled on battery when not connected to a device
- Adds a systemd drop-in so powerdevil starts after `tlp-pd` (fixes race condition
  where Plasma battery widget doesn't show profile controls on boot)

## Install

```bash
sudo ./install.sh
```

Requires internet access (adds linrunner PPA). A reboot or logout/login is
recommended after install for Plasma to pick up the D-Bus interface.

## Files

- `install.sh` — installs TLP 1.10.2 + tlp-pd, applies config
- `tlp.conf` — the tuned TLP configuration
- `powerdevil-after-tlp-pd.conf` — systemd drop-in for powerdevil ordering
