# Ubuntu Fixes

Fixes and tuning for Ubuntu 26.04+ laptops (KDE Plasma 6, Wayland). The issues
are architecture-level — Intel ACPI GPE storms, Intel WiFi resume hangs,
NVIDIA hybrid graphics power, TLP/EPP tuning — so each fix detects whether the
hardware or software it targets is present, rather than checking for a model.

Each fix lives in its own folder under `fixes/` with a README, an `install.sh`,
and an `applies.sh` that checks whether it's relevant to the current machine.

Run them interactively (as your regular user — it asks before each fix and uses sudo where needed):

```bash
./fixes.sh --list   # → applies   ✓ already applied   ✗ not applicable
./fixes.sh          # y/n/r(eadme)/q per fix; defaults to Yes only when it applies
```

`fixes.sh` requires Ubuntu 26.04 or newer.

### Writing a fix

- `install.sh` — runs as root by default. Put `# Run as your regular user` on
  line 2 if it edits `$HOME` or calls sudo itself.
- `applies.sh` — runs as the user, prints a one-line reason, and exits
  `0` = applies, `1` = not applicable, `2` = already applied.

## Tested on

| Machine | CPU | GPU | WiFi |
|---|---|---|---|
| Dell Precision 7560 | Intel i7-11850H (Tiger Lake-H) | NVIDIA RTX A2000 Mobile (hybrid) | Intel AX201/AX210 |
| Dell Precision 7510 | Intel i7-6820HQ (Skylake-H) | NVIDIA Quadro M2000M (hybrid) | Intel AX210 |

## Fixes

| Folder | What it fixes | Detects |
|---|---|---|
| `fixes/acpi-gpe-storm` | Runaway ACPI GPE interrupt (~1500/sec) draining battery | any GPE over 100/s |
| `fixes/tlp-battery` | TLP + tlp-pd install, battery-tuned drop-in, Plasma slider | laptop with intel_pstate / amd-pstate |
| `fixes/nvidia-power` | NVIDIA GPU idle power draw (17W → suspended) | hybrid GPU + nvidia driver |
| `fixes/lid-close-power` | Laptop running hot with lid closed on AC | lid + TLP |
| `fixes/wifi-sleep-resume` | Intel WiFi hangs the desktop after suspend/resume | iwlwifi |
| `fixes/powerdevil-tlp-ordering` | Plasma battery widget not showing TLP power profile controls | Plasma + tlp-pd |
| `fixes/docker-autostart` | Docker + containers (e.g. Airflow) silently running at boot | Docker enabled at boot |
| `fixes/claude-memory` | Claude Code memories for my home dir (herdr workflow preferences) | memories not installed |

## Results

| Machine | Idle on battery before | After |
|---|---|---|
| Precision 7560 | ~20–25W | **~6W** |
| Precision 7510 (4K panel, Skylake, ASPM locked by firmware) | ~24W | **~12–13W** |
