# Fix: Laptop Runs Hot with Lid Closed on AC

## Problem

KDE Powerdevil by default does nothing when the lid is closed on AC power
(`lidAction=64`). The machine keeps running at full AC performance profile
even with the lid shut, causing heat buildup.

## Fix

acpid runs a handler on every lid event and reads the lid state:

- **Closed:** `tlp bat` (battery settings even on AC), the lowest platform profile
  the firmware offers (`low-power`, `quiet` or `cool`), and a CPU package power
  cap of 15W sustained / 20W burst (RAPL PL1/PL2).
- **Open:** `tlp start` for the real power source, and the CPU power limits saved
  at close are restored.

### RAPL: two interfaces

Intel CPUs expose the package power limit twice: through an MSR
(`/sys/class/powercap/intel-rapl/intel-rapl:0`) and through MMIO
(`/sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0`). Firmware may enforce
one and reject writes to the other. On a Precision 7510 the MSR zone reports
`enabled=0` and writes fail with `No data available`, while the MMIO zone accepts
them. The scripts write both, read back the result, and log which one took.
`install.sh` reports which zones are writable; if none are, lid close still
switches TLP and the platform profile, without the cap.

Limits are saved in `/run/lid-close-power.rapl` and never restored as 0 (a zero
PL2 pins the CPU at its minimum frequency).

## Install

```bash
sudo ./install.sh
```

No reboot required.

## Verify

Close and open the lid, then:
```bash
journalctl -t ubuntu-fixes/lid-closed -t ubuntu-fixes/lid-open             # everything
journalctl -t ubuntu-fixes/lid-closed -t ubuntu-fixes/lid-open -g changed: # only changes
```

Every setting the scripts touch logs one line: `changed: <what> <before> -> <after>`,
or `unchanged: <what> ...` with the reason (already set, or rejected by firmware).

## Files

- `acpi-lid.event` — acpid event (`/etc/acpi/events/lid-close-power`)
- `acpi-lid.sh` — handler that reads the lid state (`/etc/acpi/lid.sh`)
- `lid-closed.sh`, `lid-open.sh` — the actions (`/usr/local/bin/lid-closed`, `lid-open`)
- `install.sh` — installs the above, removes the old udev rule, checks RAPL zones
- `applies.sh` — used by `fixes.sh` to decide whether this fix applies
