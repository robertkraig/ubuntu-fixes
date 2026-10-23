# Fix: KDE Connect Daemon Waking the CPU

## Problem

KDE Connect (`kdeconnectd`) pairs your desktop with a phone: notifications, clipboard
sharing, file transfer, remote input. It's installed with Plasma and starts at login,
then keeps broadcasting on the network to discover phones.

On a Precision 7510 it was the busiest process in PowerTOP while idle: ~61 wakeups/s,
estimated ~1.1W. Disabling its autostart isn't enough — the Plasma tray applet and
the Share menu start it again over D-Bus.

## Fix

Purge the `kdeconnect` package and stop the running daemon. Plasma doesn't depend
on it. Skip this fix if you use the KDE Connect app on your phone.

## Install

```bash
sudo ./install.sh
```

## Undo

```bash
sudo apt install kdeconnect
```

## Files

- `install.sh` — purges `kdeconnect` and stops `kdeconnectd`
- `applies.sh` — used by `fixes.sh` to decide whether this fix applies
