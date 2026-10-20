# Fix: Thunderbolt 4 / USB4 Controllers Idle Power Draw

## Problem

On Tiger Lake-H systems, the Thunderbolt 4 PCIe root ports and NHI controller
default to `power/control=on` (runtime PM disabled). With nothing plugged into
the Thunderbolt ports, they still draw ~1-2W continuously.

Setting `power/control=auto` lets the kernel suspend them when idle.

## What it does

Installs a udev rule that sets `power/control=auto` on the three affected
devices when they appear at boot:

- `8086:9a2b` — TB4 PCIe Root Port #0
- `8086:9a2d` — TB4 PCIe Root Port #1
- `8086:9a1f` — TB4 NHI #0

## Detects

Presence of any of the three PCI device IDs via `lspci`.

## Tested on

- Dell Precision 7560 (Tiger Lake-H)
