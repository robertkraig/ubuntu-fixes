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

The unload uses `rmmod`, not `modprobe -r`: Ubuntu's `/etc/modprobe.d/iwlwifi.conf`
(from `kmod`) has its own `remove iwlwifi` rule, so `modprobe -r iwlmvm iwlwifi`
unloads both on the first name and then fails on the second. A failed start
means systemd never runs the reload on resume, leaving WiFi off. The unload
step always exits 0 for that reason.

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

## WiFi still off after resume?

```bash
wifi-up            # installed by install.sh, or: sudo ./wifi-up.sh from this folder
```

Loads the driver again (unloading it first if it's loaded but has no interface),
clears the service's failed state, unblocks rfkill and turns the NetworkManager
radio on. It finds the driver from the installed service or `lspci`, since the
interface doesn't exist while the driver is unloaded.

## Uninstall

```bash
sudo systemctl disable wifi-sleep-unload.service
sudo rm /etc/systemd/system/wifi-sleep-unload.service /usr/local/bin/wifi-up
```

## Files

- `install.sh` — detects the driver and installs `wifi-sleep-unload.service`
- `wifi-up.sh` — manual recovery, installed as `/usr/local/bin/wifi-up`
- `applies.sh` — used by `fixes.sh` to decide whether this fix applies
