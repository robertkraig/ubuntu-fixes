# Fix: Intel WiFi Driver Stuck State After Suspend/Resume

## Problem

On Intel WiFi adapters (particularly AX series), the driver can enter a stuck
state after resuming from suspend when on battery. The adapter shows as up but
cannot connect, requiring a manual `ip link set wlp... down/up` or reboot to recover.

## Fix

A systemd sleep hook that brings the WiFi interface down before sleep and back
up on resume — but only when on battery (no disruption when on AC).

## Install

```bash
sudo ./install.sh
```

Edit `wifi-cycle` first if your WiFi interface name differs from `wlp147s0f0`:
```bash
ip link show | grep -E "wlan|wlp"
```

No reboot required.

## Files

- `wifi-cycle` — systemd sleep hook, goes in `/usr/lib/systemd/system-sleep/`

## Affected hardware

- Dell Precision 7510, 7560 (Intel AX201/AX210 WiFi)
- Various Intel 11th/12th gen laptops with AX series WiFi
