#!/data/data/com.termux/files/usr/bin/bash
# TTL Spoofing Service
# Purpose: Make traffic appear as "network management" or "tethered"
# Some carriers exempt these categories from data caps

IFACE=$(su -c "ip route | grep default | awk '{print \$5}' | head -1")

case "$1" in
    tether)
        # Appear as USB tethered traffic (often exempt)
        su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set 64"
        echo "[+] TTL set to 64 (tethered appearance)"
        ;;
    local)
        # Appear as local loop (very risky, may break)
        su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set 1"
        echo "[+] TTL set to 1 (local appearance - EXPERIMENTAL)"
        ;;
    random)
        # Randomize to evade pattern detection
        su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set \$((RANDOM % 20 + 60))"
        echo "[+] TTL randomized (60-80)"
        ;;
    reset)
        su -c "iptables -t mangle -F"
        echo "[+] TTL rules reset"
        ;;
    *)
        echo "Usage: $0 {tether|local|random|reset}"
        exit 1
        ;;
esac