# Fix: Runaway ACPI GPE6E Interrupt

## Problem

The ACPI GPE6E interrupt fires ~1,500 times per second on certain Dell/Intel
laptops, causing constant CPU wakeups and significant battery drain.

Check if you're affected:
```bash
cat /sys/firmware/acpi/interrupts/gpe6E
```
If the count is climbing rapidly (refresh a few times), you have this bug.

## Fix

Add `acpi_mask_gpe=0x6E` to your GRUB kernel parameters. This tells the kernel
to mask (ignore) the interrupt permanently.

## Install

```bash
sudo ./install.sh
```

The script edits `/etc/default/grub` and runs `update-grub`. A reboot is
required to apply.

## Runtime-only (no reboot)

```bash
sudo ./mask-runtime.sh
```

Masks the interrupt immediately without a reboot. Does not persist across reboots.

## Affected hardware

- Dell Precision 7560
- Dell Precision 7510 (and likely other 75xx/74xx models)
- Various Intel 11th gen laptops
