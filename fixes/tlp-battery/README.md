# Fix: TLP Battery Optimization + Plasma UI Integration

## Problem

Ubuntu ships `power-profiles-daemon` as the default power manager. TLP 1.9+
with `tlp-pd` gives much more granular battery control and still integrates
with the KDE Plasma (and GNOME) power-profile slider, because `tlp-pd`
implements the same `net.hadess.PowerProfiles` D-Bus interface.

Applies to laptops whose CPU uses `intel_pstate` or `amd-pstate` (HWP/EPP).

## What this does

- Installs TLP + `tlp-pd` from the linrunner PPA
- Disables `power-profiles-daemon`
- Writes `/etc/tlp.d/00-ubuntu-fixes.conf` (a drop-in, **not** `/etc/tlp.conf`):
  - Governor `powersave` everywhere; EPP does the work
    (`balance_performance` / `balance_power` / `power` for performance / balanced / power-saver)
  - No CPU cap and turbo on in balanced; power-saver caps at 50% with no turbo
  - Platform profile picked from what the firmware offers
    (`/sys/firmware/acpi/platform_profile_choices`)
  - Bluetooth off on battery when nothing is connected, back on with AC

## Per-machine overrides

TLP reads `/etc/tlp.d/*.conf` in order, then `/etc/tlp.conf` last.
Put machine-specific tuning in a later drop-in such as
`/etc/tlp.d/50-local.conf` — it overrides this one. Settings in
`/etc/tlp.conf` override everything; `install.sh` warns if it finds any.

## Install

```bash
sudo ./install.sh
```

Requires internet access (adds the linrunner PPA). If the Plasma slider
doesn't appear, run `systemctl --user restart plasma-powerdevil` or log out and in.

## Files

- `install.sh` — installs TLP + tlp-pd, writes the drop-in
- `tlp.conf` — drop-in template (`{{PLATFORM_PROFILE}}` is filled in at install)
- `applies.sh` — used by `fixes.sh` to decide whether this fix applies
