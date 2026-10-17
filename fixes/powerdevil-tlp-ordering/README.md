# Fix: Plasma Battery Widget Not Showing TLP Power Profile Controls

## Problem

After installing `tlp-pd`, the KDE Plasma battery widget should show power
profile controls (Performance / Balanced / Power Saver). It often doesn't on
first boot because `plasma-powerdevil` starts before `tlp-pd` has fully
initialized its D-Bus interface (`net.hadess.PowerProfiles`).

Powerdevil checks for the interface at startup and caches the result — if
`tlp-pd` isn't ready yet, the profile controls never appear without a manual
powerdevil restart.

## Fix

A systemd user-level drop-in that orders `plasma-powerdevil` to start after
`tlp-pd.service`.

## Install

Run as your **regular user** (not root):

```bash
./install.sh
```

## Verify

After next login, click the battery icon in the system tray — you should see
a "Power Profile" section with Performance / Balanced / Power Saver options.

Or check via D-Bus:
```bash
qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.currentProfile
```
