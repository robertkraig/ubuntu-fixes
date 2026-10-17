# Fix: Intel WiFi Hangs the Desktop After Suspend/Resume

## Problem

Intel WiFi cards (`iwlwifi`, e.g. AX201/AX210) can fail to come back from
S3 suspend: register reads return `0xffffffff`, then the firmware fails to
start (`Failed to start RT ucode: -110`).

NetworkManager gets stuck in the kernel trying to bring the card up while
holding the global network lock (rtnl). Everything that touches networking
then blocks behind it — the Plasma network applet, plasmashell, browsers —
so the desktop stops responding, WiFi can't be re-enabled, and logging out
doesn't help. Only a reboot recovers.

Seen on both AC and battery, and the card sometimes recovers on one resume
and not the next.

## Fix

A systemd service tied to `sleep.target` that unloads the WiFi driver (and
the modules that depend on it, e.g. `iwlmvm`) before sleep and loads it again
on resume, so the card always initialises from scratch.

The driver and its dependents are detected at install time.

## Install

```bash
sudo ./install.sh
```

No reboot required. Replaces the older `wifi-cycle` interface down/up hook if present.

## Verify

Suspend, resume, and check:
```bash
journalctl -b -k | grep -iE 'iwlwifi.*(error|fail|timeout)'
```

## Uninstall

```bash
sudo systemctl disable wifi-sleep-unload.service
sudo rm /etc/systemd/system/wifi-sleep-unload.service
```

## Files

- `install.sh` — detects the driver and installs `wifi-sleep-unload.service`
- `applies.sh` — used by `fixes.sh` to decide whether this fix applies
