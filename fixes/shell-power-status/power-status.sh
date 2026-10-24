#!/bin/bash
# Print the laptop's power state in two lines. Shown when a terminal opens.
# Reads sysfs with the read builtin and one busctl call: every external command
# costs ~20ms to start (tlpctl alone takes 0.5s), so this avoids them.

if [ -t 1 ]; then
    R=$'\e[0m' DIM=$'\e[2m' BOLD=$'\e[1m' RED=$'\e[31m' GRN=$'\e[32m' YEL=$'\e[33m' CYN=$'\e[36m'
fi
SEP=" ${DIM}·${R} "

rd() { { read -r "$1" < "$2"; } 2>/dev/null; }   # rd VAR FILE
fmt_time() { printf -v "$1" '%dh%02dm' $(( $2 / 60 )) $(( $2 % 60 )); }

# Power profile (power-profiles-daemon or tlp-pd, same D-Bus API)
profile=$(busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles \
    net.hadess.PowerProfiles ActiveProfile 2>/dev/null)
profile=${profile#s \"}; profile=${profile%\"}
case "$profile" in
    performance) pcol=$RED ;;
    balanced)    pcol=$YEL ;;
    power-saver) pcol=$GRN ;;
esac
line1="${BOLD}${pcol}${profile:-no power profile}${R}"

# Battery: percent, direction, draw, time left
for bat in /sys/class/power_supply/BAT*; do
    rd cap "$bat/capacity" || continue
    rd status "$bat/status"
    # µW from power_now, or µV × µA from voltage/current
    if ! rd uw "$bat/power_now"; then
        rd uv "$bat/voltage_now"; rd ua "$bat/current_now"
        uw=$(( uv / 1000 * ua / 1000 ))
    fi
    printf -v watts '%d.%dW' $(( uw / 1000000 )) $(( uw / 100000 % 10 ))
    case "$status" in
        Discharging)
            left=""
            if rd now "$bat/energy_now" && [ "$uw" -gt 0 ]; then
                fmt_time left $(( now * 60 / uw )); left=" ~$left"
            elif rd now "$bat/charge_now" && rd ua "$bat/current_now" && [ "$ua" -gt 0 ]; then
                fmt_time left $(( now * 60 / ua )); left=" ~$left"
            fi
            [ "$cap" -le 20 ] && ccol=$RED || ccol=""
            line1+="${SEP}battery ${ccol}${cap}%${R} ↓ ${watts}${left}" ;;
        Charging) line1+="${SEP}AC ${CYN}${cap}% ↑ charging${R} ${watts}" ;;
        *)        line1+="${SEP}AC ${cap}% ${DIM}(${status,,})${R}" ;;
    esac
    rd start "$bat/charge_control_start_threshold" && rd stop "$bat/charge_control_end_threshold" \
        && limits="charge $start-$stop%"
    break
done

# NVIDIA on a hybrid system: prime-select mode and whether the GPU is powered
for dev in /sys/bus/pci/devices/*; do
    rd vendor "$dev/vendor"; [ "$vendor" = 0x10de ] || continue
    rd class "$dev/class";   [[ "$class" == 0x03* ]] || continue
    rd prime /etc/prime-discrete
    case "$prime" in
        off) mode=intel ;; on) mode=nvidia ;; on-demand) mode=on-demand ;; *) mode="" ;;
    esac
    rd state "$dev/power/runtime_status"
    if [ "$state" = suspended ]; then
        line1+="${SEP}NVIDIA ${GRN}off${R}${mode:+ ${DIM}($mode)${R}}"
    else
        line1+="${SEP}NVIDIA ${YEL}${state:-on}${R}${mode:+ ${DIM}($mode)${R}}"
    fi
    break
done

# Second line: what the profile translates to
cpu=/sys/devices/system/cpu
line2=""
add() { line2+="${line2:+ · }$1"; }
rd epp $cpu/cpu0/cpufreq/energy_performance_preference && add "epp $epp"
if rd maxp $cpu/intel_pstate/max_perf_pct; then
    add "cpu max $maxp%"
    rd noturbo $cpu/intel_pstate/no_turbo
    [ "$noturbo" = 1 ] && add "turbo off" || add "turbo on"
elif rd boost $cpu/cpufreq/boost; then
    [ "$boost" = 1 ] && add "turbo on" || add "turbo off"
fi
rd pp /sys/firmware/acpi/platform_profile && add "platform $pp"
[ -n "$limits" ] && add "$limits"

echo "$line1"
[ -n "$line2" ] && echo "${DIM}${line2}${R}"
exit 0
