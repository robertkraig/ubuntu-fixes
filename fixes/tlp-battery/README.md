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
    (`performance` on AC, `balance_power` on battery, `power` in power-saver)
  - No CPU cap and turbo on in balanced; power-saver caps at 50% with no turbo
  - Platform profile picked from what the firmware offers
    (`/sys/firmware/acpi/platform_profile_choices`)
  - Intel GPU clocks (i915) from the GPU's own range: full range on AC and
    battery, two thirds of max in power-saver. AC and battery are set explicitly,
    since TLP leaves an unset value where the last mode put it.
  - Charge thresholds 50/80
  - Bluetooth off on battery when nothing is connected, back on with AC

## Per-machine overrides

TLP reads `/etc/tlp.d/*.conf` in order, then `/etc/tlp.conf` last, and later
settings win. The goal is the same behavior on every laptop, so this drop-in
owns its settings:

- Active lines in `/etc/tlp.conf` are commented out; the ones this drop-in
  doesn't set are moved to `/etc/tlp.d/50-local.conf`.
- In later drop-ins (`01-*.conf`, `50-local.conf`, …), lines that set a key this
  drop-in sets are commented out as `# overridden by ubuntu-fixes: KEY=...`.
  Everything else in them stays active.

Hardware differences are detected at install time instead (platform profiles,
GPU clocks). To change a value everywhere, change `tlp.conf` here.
`applies.sh` reports the fix as stale if anything overrides it.

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
