#!/data/data/com.termux/files/usr/bin/bash
# TTL Spoofing

IFACE=$(cat /data/local/tmp/iotshaper_iface 2>/dev/null)
[ -z "$IFACE" ] && IFACE=$(su -c "ip link show | grep -E 'ccmni[0-9]+|rmnet_data[0-9]+|rmnet[0-9]+|eth[0-9]+' | grep 'UP,LOWER_UP' | grep -v 'wlan\|lo' | head -1 | awk -F: '{print \$2}' | awk '{print \$1}'")
[ -z "$IFACE" ] && IFACE=$(su -c "ip route | grep default | awk '{print \$5}' | grep -v 'wlan\|lo' | head -1")
[ -z "$IFACE" ] && IFACE="ccmni1"
[ -z "$IFACE" ] && IFACE="rmnet_data0"

case "$1" in
    tether) su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set 64"; echo "[+] TTL=64 on $IFACE" ;;
    local) su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set 1"; echo "[+] TTL=1 on $IFACE" ;;
    random) su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set $((RANDOM % 20 + 60))"; echo "[+] TTL randomized on $IFACE" ;;
    reset) su -c "iptables -t mangle -F"; echo "[+] TTL reset" ;;
    *) echo "Usage: ttl {tether|local|random|reset}" ;;
esac
