# Fix: KDE Compositor Effects Drain Battery

## Problem

KWin effects like blur, wobbly windows, scale/slide animations and background
contrast keep the GPU busy redrawing, which costs power on battery.

## Fix

- On battery: remember which of the listed effects are loaded, then unload them.
- On AC: reload exactly those effects, so your KWin settings are kept.

Triggered at login (systemd user service) and on charger plug/unplug (udev rule
that runs the script in your session via `systemd-run --user`).

Effects managed: wobblywindows, scale, squash, translucency, blur,
backgroundcontrast, fadingpopups, slide, zoom, magic lamp.

## Install

```bash
sudo ./install.sh
```

Installs for the user who ran sudo. If you're on battery, effects turn off immediately.

## Manual control

```bash
~/.local/bin/kde-battery-effects-off.sh   # unload now
~/.local/bin/kde-battery-effects-on.sh    # restore now
```

## Files

- `kde-power-effects.sh` — the toggle (installed to `~/.local/bin`)
- `install.sh` — installs the script, user service, and udev rule
- `applies.sh` — used by `fixes.sh` to decide whether this fix applies
