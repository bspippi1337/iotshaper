#!/data/data/com.termux/files/usr/bin/bash
# TTL Spoofing Service

IFACE=$(su -c "ip route | grep default | awk '{print $5}' | head -1")

case "$1" in
    tether) su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set 64"; echo "[+] TTL=64 (tethered)" ;;
    local) su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set 1"; echo "[+] TTL=1 (local)" ;;
    random) su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set $((RANDOM % 20 + 60))"; echo "[+] TTL randomized" ;;
    reset) su -c "iptables -t mangle -F"; echo "[+] TTL reset" ;;
    *) echo "Usage: ttl {tether|local|random|reset}" ;;
esac
