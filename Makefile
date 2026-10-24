SHELL     := /bin/bash
FIXES_DIR := fixes
FIXES     := acpi-gpe-storm claude-memory docker-autostart ethernet-power \
             kde-battery-effects kdeconnect-remove lid-close-power nvidia-power \
             powerdevil-tlp-ordering shell-power-status ssd-tuning thunderbolt-power tlp-battery wifi-sleep-resume

.PHONY: all list status help $(FIXES)

# ── Help ──────────────────────────────────────────────────────────────────────

help:
	@echo ""
	@echo "Laptop power and stability fixes for Ubuntu 26.04+ — each fix detects the"
	@echo "hardware it applies to. Tested on Dell Precision 7510 and 7560 (KDE Plasma 6)."
	@echo ""
	@echo "Usage:"
	@echo "  make list               Show status of all fixes (applied / stale / n/a)"
	@echo "  make all                Run all applicable fixes interactively"
	@echo "  make <fix>              Deploy one fix directly, no prompt"
	@echo ""
	@echo "Fixes:"
	@echo "  acpi-gpe-storm          Mask any ACPI GPE firing over 100/s (firmware bug, blocks deep idle)"
	@echo "  claude-memory           Install Claude Code memory files for this workflow"
	@echo "  docker-autostart        Don't start Docker/containerd at boot; add docker-start/stop aliases"
	@echo "  ethernet-power          Take wired ethernet down on battery when no cable is plugged in"
	@echo "  kde-battery-effects     Turn KWin blur/animations off on battery, restore them on AC"
	@echo "  kdeconnect-remove       Remove KDE Connect (kdeconnectd wakes the CPU ~60x/s, ~1W)"
	@echo "  lid-close-power         Lid closed: TLP battery settings, quietest platform profile, 15W CPU cap"
	@echo "  nvidia-power            Hybrid NVIDIA: Intel-only mode, GPU fully powered off (incl. HDMI audio)"
	@echo "  powerdevil-tlp-ordering Start PowerDevil after tlp-pd so Plasma shows the power profile slider"
	@echo "  shell-power-status      Show power profile, battery and GPU state in new terminals"
	@echo "  ssd-tuning              noatime on ext4 mounts + zram swap (fewer SSD writes)"
	@echo "  thunderbolt-power       Let idle Thunderbolt/USB4 controllers suspend (~1-2W)"
	@echo "  tlp-battery             TLP + Plasma profile slider, 50-80% charge limits, detected GPU clocks"
	@echo "  wifi-sleep-resume       Reload the WiFi driver across suspend (Intel iwlwifi resume hang)"
	@echo ""
	@echo "Tools (installed by the fixes above):"
	@echo "  power-status            Print the current power profile, battery draw and GPU state"
	@echo "  sudo wifi-up            Bring WiFi back after a failed resume (reloads driver, resets PCI)"
	@echo "  sudo tlp fullcharge     Charge to 100% once; 'sudo tlp setcharge' restores the limits"
	@echo ""
	@echo "Logs:  journalctl -b | grep ubuntu-fixes/              (everything)"
	@echo "       journalctl -b | grep ubuntu-fixes/ | grep changed:   (only what changed)"
	@echo ""

# ── Targets ───────────────────────────────────────────────────────────────────

all:
	@bash fixes.sh

list:
	@bash fixes.sh --list

status: list

# Per-fix: check applies.sh first, then run install.sh
$(FIXES):
	@dir=$(FIXES_DIR)/$@; \
	[ -f "$$dir/install.sh" ] || { echo "No install.sh for $@"; exit 1; }; \
	rc=0; reason=$$(bash "$$dir/applies.sh" 2>&1) || rc=$$?; \
	[ $$rc -eq 1 ] && { echo "Skipping $@: $$reason"; exit 0; }; \
	[ $$rc -eq 2 ] && { echo "Already applied: $$reason"; exit 0; }; \
	if grep -q '^# Run as your regular user' "$$dir/install.sh"; then \
	    bash "$$dir/install.sh"; \
	else \
	    sudo bash "$$dir/install.sh"; \
	fi
