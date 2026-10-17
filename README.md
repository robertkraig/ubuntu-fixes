# Ubuntu Fixes — Dell Precision 7560

A collection of fixes and tuning applied to a Dell Precision 7560 running Ubuntu 26.04 (Resolute Raccoon) with KDE Plasma 6 on Wayland.

Each fix lives in its own folder under `fixes/` with a README and an `install.sh`.

## Hardware
- **Machine:** Dell Precision 7560
- **CPU:** Intel i7-11850H
- **GPU:** NVIDIA RTX A2000 Mobile (Optimus hybrid)
- **OS:** Ubuntu 26.04 LTS, KDE Plasma 6.6, Wayland, Kernel 7.0

## Fixes

| Folder | What it fixes |
|---|---|
| `fixes/acpi-gpe6e` | Runaway ACPI GPE6E interrupt (~1500/sec) draining battery |
| `fixes/tlp-battery` | TLP 1.10.2 install + battery-optimized config + Plasma UI integration |
| `fixes/nvidia-power` | NVIDIA GPU idle power draw (17W → suspended) |
| `fixes/lid-close-power` | Laptop running hot with lid closed on AC |
| `fixes/wifi-sleep-resume` | Intel WiFi driver stuck state after suspend/resume on battery |
| `fixes/powerdevil-tlp-ordering` | Plasma battery widget not showing TLP power profile controls |
| `fixes/docker-autostart` | Docker + containers (e.g. Airflow) silently running at boot |

## Results

Starting idle power draw: ~20–25W
After all fixes: **~6W idle on battery**
