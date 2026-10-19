SHELL    := /bin/bash
FIXES    := acpi-gpe-storm claude-memory docker-autostart kde-battery-effects \
            lid-close-power nvidia-power powerdevil-tlp-ordering tlp-battery \
            wifi-sleep-resume
FIXES_DIR := fixes

.PHONY: all list status help $(FIXES)

## Show this help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "  all              Run all applicable fixes (interactive)"
	@echo "  list             Show fix status (applies / already applied / not applicable)"
	@echo "  status           Alias for list"
	@echo "  <fix-name>       Run one fix directly (skips prompt)"
	@echo ""
	@echo "Fixes:"
	@for f in $(FIXES); do printf "  %-32s\n" "$$f"; done

## Run all fixes interactively
all:
	@bash fixes.sh

## Show status of all fixes
list:
	@bash fixes.sh --list

status: list

# Per-fix targets — run a single install.sh without the interactive prompt
$(FIXES):
	@dir=$(FIXES_DIR)/$@; \
	if [ ! -f "$$dir/install.sh" ]; then echo "No install.sh for $@"; exit 1; fi; \
	rc=0; reason=$$(bash "$$dir/applies.sh" 2>&1) || rc=$$?; \
	if [ $$rc -eq 1 ]; then echo "Skipping $@: $$reason"; exit 0; fi; \
	if [ $$rc -eq 2 ]; then echo "Already applied: $$reason"; exit 0; fi; \
	if grep -q '^# Run as your regular user' "$$dir/install.sh"; then \
	    bash "$$dir/install.sh"; \
	else \
	    sudo bash "$$dir/install.sh"; \
	fi
