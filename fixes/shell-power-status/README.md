# Fix: No Power State When Opening a Terminal

## Problem

With TLP profiles, Optimus and charge thresholds all in play, there's no quick way
to see which mode the laptop is in. `tlpctl get` takes ~0.5s, `prime-select query`
~0.15s, and the battery numbers are scattered across sysfs.

## Fix

`power-status` prints two lines, and runs when an interactive terminal opens:

```
power-saver · battery 77% ↓ 10.9W ~6h40m · NVIDIA off (intel)
epp power · cpu max 50% · turbo off · platform quiet · charge 50-80%
```

- **Line 1:** power profile (green power-saver, yellow balanced, red performance),
  battery percent, discharge rate and time left, or AC/charging, and the NVIDIA
  GPU's power state with the `prime-select` mode on hybrid systems.
- **Line 2:** what the profile translates to: EPP, CPU max %, turbo, ACPI platform
  profile, charge thresholds.

Each part only appears if the hardware has it. It reads sysfs with bash's `read`
builtin plus one `busctl` call (the power profile, which works with both
`power-profiles-daemon` and `tlp-pd`), so it takes ~0.1s. On Ubuntu 26.04 every
external command costs ~20ms to start, which is why it avoids `cat`.

## Install

```bash
./install.sh
```

Installs `~/.local/bin/power-status` and adds a hook to `~/.zshrc` and/or
`~/.bashrc`. Run `power-status` any time to check again.

## Undo

Delete the `# ubuntu-fixes: power-status` lines from your shell rc and
`~/.local/bin/power-status`.

## Files

- `power-status.sh` — the status script (installed as `~/.local/bin/power-status`)
- `install.sh` — installs it and hooks it into your shell rc
- `applies.sh` — used by `fixes.sh` to decide whether this fix applies
