#!/bin/bash
# Called by udev when lid closes. Reduce heat aggressively.

/usr/sbin/tlp bat

# Force low-power platform profile
echo low-power > /sys/firmware/acpi/platform_profile 2>/dev/null || true

# Cap CPU package power (RAPL): 15W sustained, 20W burst (PL1/PL2)
# This is the biggest single lever for heat reduction under lid.
for zone in /sys/class/powercap/intel-rapl/intel-rapl:0; do
    [ -f "$zone/constraint_0_power_limit_uw" ] && echo 15000000 > "$zone/constraint_0_power_limit_uw" || true
    [ -f "$zone/constraint_1_power_limit_uw" ] && echo 20000000 > "$zone/constraint_1_power_limit_uw" || true
done
