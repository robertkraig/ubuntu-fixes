#!/bin/bash
# Called by udev when lid opens. Restore full performance.

/usr/sbin/tlp ac

# Restore balanced platform profile
echo balanced > /sys/firmware/acpi/platform_profile 2>/dev/null || true

# Remove CPU power cap — restore BIOS defaults by writing max values
for zone in /sys/class/powercap/intel-rapl/intel-rapl:0; do
    [ -f "$zone/constraint_0_max_power_uw" ] && \
        cat "$zone/constraint_0_max_power_uw" > "$zone/constraint_0_power_limit_uw" || true
    [ -f "$zone/constraint_1_max_power_uw" ] && \
        cat "$zone/constraint_1_max_power_uw" > "$zone/constraint_1_power_limit_uw" || true
done
