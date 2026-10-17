# Fix: Laptop Runs Hot with Lid Closed on AC

## Problem

KDE Powerdevil by default does nothing when the lid is closed on AC power
(`lidAction=64`). The machine keeps running at full AC performance profile
even with the lid shut, causing heat buildup.

## Fix

A udev rule that triggers `tlp bat` (battery power profile) when the lid closes
and `tlp ac` when it opens — regardless of whether the machine is on AC or battery.

This drops the CPU to the battery profile when the lid is closed, reducing heat
significantly without suspending the machine.

## Install

```bash
sudo ./install.sh
```

No reboot required — udev rules are hot-reloaded.

## Files

- `99-lid-tlp.rules` — udev rule for lid open/close events
