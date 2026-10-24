# Fix: Thunderbolt 4 / USB4 Controllers Idle Power Draw

## Problem

On some systems (seen on Tiger Lake-H), the Thunderbolt PCIe root ports and NHI
controller default to `power/control=on` (runtime PM disabled). With nothing
plugged into the Thunderbolt ports, they still draw ~1-2W continuously.

Setting `power/control=auto` lets the kernel suspend them when idle.

## What it does

Installs a udev rule that sets `power/control=auto` on every PCI device whose
PCI database name contains "Thunderbolt" or "USB4" when it appears at boot, and
applies the same to devices already present. Matching by name instead of device
ID covers Intel integrated Thunderbolt (Ice Lake and newer), discrete Intel
Thunderbolt controllers, and AMD USB4 without a per-generation ID list.

## Detects

Any device `lspci` names as Thunderbolt or USB4.

## Tested on

- Dell Precision 7560 (Tiger Lake-H): `8086:9a2b`, `8086:9a2d` root ports, `8086:9a1f` NHI
