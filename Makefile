SHELL     := /bin/bash
FIXES_DIR := fixes
FIXES     := acpi-gpe-storm claude-memory docker-autostart ethernet-power \
             kde-battery-effects kdeconnect-remove lid-close-power nvidia-power \
             powerdevil-tlp-ordering ssd-tuning thunderbolt-power tlp-battery wifi-sleep-resume

.PHONY: all list status help $(FIXES)

# ── Help ──────────────────────────────────────────────────────────────────────

help:
	@echo ""
	@echo "Ubuntu fixes for Dell Precision 7560 / 7510 — Ubuntu 26.04 KDE Plasma 6"
	@echo ""
	@echo "Usage:"
	@echo "  make list              Show status of all fixes (applied / stale / n/a)"
	@echo "  make all               Run all applicable fixes interactively"
	@echo "  make <fix>             Deploy one fix directly, no prompt"
	@echo ""
	@echo "Fixes:"
	@echo "  acpi-gpe-storm         Silence runaway ACPI GPE interrupt storm (Tiger Lake firmware bug)"
	@echo "  claude-memory          Install Claude Code memory integration"
	@echo "  docker-autostart       Disable Docker/containerd at boot — saves ~8W idle drain"
	@echo "  ethernet-power         Down wired ethernet on battery when no cable — saves ~5W"
	@echo "  kde-battery-effects    Disable compositor blur/wobble/animations on battery, restore on AC"
	@echo "  kdeconnect-remove      Purge KDE Connect — kdeconnectd wakes the CPU ~60x/s (~1W)"
	@echo "  lid-close-power        Cap CPU at 15W when lid is closed on AC — prevents overheating"
	@echo "  nvidia-power           Force Intel-only GPU mode — stops NVIDIA drawing ~17W at idle"
	@echo "  powerdevil-tlp-ordering  Fix KDE battery widget not showing TLP power profile controls"
	@echo "  ssd-tuning             Add noatime to ext4 mounts + enable zram — reduces SSD wear"
	@echo "  thunderbolt-power      Suspend TB4/USB4 controllers when idle — saves ~1-2W"
	@echo "  tlp-battery            Replace power-profiles-daemon with TLP for better battery life"
	@echo "  wifi-sleep-resume      Fix Intel WiFi (BE200/AX210) not coming back after suspend/resume"
	@echo ""
	@echo "Recovery:"
	@echo "  sudo wifi-up           Manually recover WiFi after a failed resume"
	@echo "  make list              Re-check which fixes have gone stale"
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
