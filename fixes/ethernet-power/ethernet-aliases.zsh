# Wired ethernet quick toggles — installed by ubuntu-fixes/ethernet-power
_eth_iface() {
    for i in $(ls /sys/class/net/); do
        [ "$i" = "lo" ] && continue
        [ -d "/sys/class/net/$i/wireless" ] && continue
        readlink "/sys/class/net/$i" 2>/dev/null | grep -qE 'virtual|veth|docker|br-' && continue
        echo "$i"; return
    done
}
eth-up()   { sudo ip link set "$(_eth_iface)" up   && echo "Ethernet up:   $(_eth_iface)"; }
eth-down() { sudo ip link set "$(_eth_iface)" down && echo "Ethernet down: $(_eth_iface)"; }
