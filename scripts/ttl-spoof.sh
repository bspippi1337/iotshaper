#!/data/data/com.termux/files/usr/bin/bash
IFACE=$(cat /data/local/tmp/iotshaper_iface 2>/dev/null)
[ -z "$IFACE" ] && IFACE=$(su -c "ip link show | grep -E 'ccmni[0-9]+:|rmnet_data[0-9]+:' | grep 'UP,LOWER_UP' | grep -v 'wlan\|lo' | head -1 | awk -F: '{print \$2}' | awk '{print \$1}'")
[ -z "$IFACE" ] && IFACE="ccmni1"
case "$1" in
    tether) su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set 64" 2>/dev/null && echo "[+] TTL=64" || echo "[!] TTL not supported" ;;
    local) su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set 1" 2>/dev/null && echo "[+] TTL=1" || echo "[!] TTL not supported" ;;
    random) su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set \$((RANDOM % 20 + 60))" 2>/dev/null && echo "[+] TTL randomized" || echo "[!] TTL not supported" ;;
    reset) su -c "iptables -t mangle -F" && echo "[+] TTL reset" ;;
    *) echo "Usage: ttl {tether|local|random|reset}" ;;
esac
