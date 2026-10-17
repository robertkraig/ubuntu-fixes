# Fix: Runaway ACPI GPE Interrupt Storm

## Problem

On many Intel laptops (seen on Skylake and Tiger Lake), a firmware bug leaves an
ACPI General Purpose Event stuck firing ~1,200–1,500 times per second. Each one
wakes the CPU and runs a firmware handler (`kworker ... kacpi_notify` shows up
in top/powertop), so the system never reaches deep idle — several watts wasted.

The GPE number varies by chipset (e.g. `gpe6D` on Skylake-H, `gpe6E` on
Tiger Lake-H), so this fix measures rather than hardcoding one.

Check if you're affected:
```bash
./detect-storm.sh      # prints "<gpe> <rate>/s" for anything over 100/s
```

## Fix

For each storming GPE, add `acpi_mask_gpe=0x<NN>` to the GRUB kernel parameters
so the kernel ignores it from boot, and mask it immediately.

Masking a GPE can stop whatever wake source it serves (often USB/PCH wake),
so test sleep/wake afterwards.

## Install

```bash
sudo ./install.sh
```

Edits `/etc/default/grub` and runs `update-grub`. Takes effect now and
persists from the next boot.

## Runtime-only (no reboot)

```bash
sudo ./mask-runtime.sh
```

## Files

- `detect-storm.sh` — samples all GPEs and reports the storming ones
- `applies.sh` — used by `fixes.sh` to decide whether this fix applies
- `install.sh` — mask now + add to GRUB
- `mask-runtime.sh` — mask now only
