#!/system/bin/sh
# Universal Network Tweaks - Any interface, any SIM

echo "[*] Detecting active mobile interface..."

# Priority 1: UP mobile interface (not WiFi, not down)
IFACE=$(ip link show | grep -E '(ccmni[0-9]+|rmnet_data[0-9]+|rmnet[0-9]+|eth[0-9]+):' | grep 'UP,LOWER_UP' | grep -v 'wlan\|lo\|dummy\|ifb\|tun\|gre\|sit' | head -1 | awk -F: '{print $2}' | awk '{print $1}')

# Priority 2: Interface with IP assigned
[ -z "$IFACE" ] && IFACE=$(ip addr show | grep -B2 'inet ' | grep -E '(ccmni[0-9]+|rmnet_data[0-9]+|rmnet[0-9]+|eth[0-9]+):' | grep -v 'wlan\|lo' | head -1 | awk -F: '{print $2}' | awk '{print $1}')

# Priority 3: Default route (non-WiFi)
[ -z "$IFACE" ] && IFACE=$(ip route | grep default | awk '{print $5}' | grep -v 'wlan\|lo' | head -1)

# Priority 4: Active data activity
[ -z "$IFACE" ] && IFACE=$(for i in /sys/class/net/ccmni*/statistics/rx_bytes 2>/dev/null; do [ -f "$i" ] && [ "$(cat $i 2>/dev/null)" -gt 0 ] 2>/dev/null && basename $(dirname $i) && break; done)

# Priority 5: Hardcoded fallbacks
[ -z "$IFACE" ] && IFACE="ccmni1"
[ -z "$IFACE" ] && IFACE="ccmni0"
[ -z "$IFACE" ] && IFACE="rmnet_data0"
[ -z "$IFACE" ] && IFACE="eth0"

echo "[*] Interface: $IFACE"

# Verify
if ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "[!] $IFACE not found, trying any available..."
    IFACE=$(ls /sys/class/net/ 2>/dev/null | grep -E 'ccmni|rmnet|eth' | grep -v 'wlan' | head -1)
    [ -z "$IFACE" ] && { echo "[!] No suitable interface"; exit 1; }
    echo "[*] Fallback: $IFACE"
fi

# Cache for other scripts
echo "$IFACE" > /data/local/tmp/iotshaper_iface 2>/dev/null

# MTU
ip link set dev "$IFACE" mtu 1280 2>/dev/null && echo "[+] MTU=1280" || echo "[!] MTU failed"

# TTL
iptables -t mangle -C POSTROUTING -o "$IFACE" -j TTL --ttl-set 65 2>/dev/null || \
    iptables -t mangle -A POSTROUTING -o "$IFACE" -j TTL --ttl-set 65 2>/dev/null
echo "[+] TTL=65"

# TCP opts
echo 3 > /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null
echo 4096 > /proc/sys/net/ipv4/tcp_rmem_min 2>/dev/null
echo 4096 > /proc/sys/net/ipv4/tcp_wmem_min 2>/dev/null
echo 0 > /proc/sys/net/ipv4/tcp_timestamps 2>/dev/null
echo 1 > /proc/sys/net/ipv4/tcp_sack 2>/dev/null
echo 0 > /proc/sys/net/ipv4/tcp_window_scaling 2>/dev/null
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_time 2>/dev/null
echo 3 > /proc/sys/net/ipv4/tcp_keepalive_probes 2>/dev/null
echo 5 > /proc/sys/net/ipv4/tcp_keepalive_intvl 2>/dev/null
echo "[+] TCP optimized"

# IPv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null && echo "[+] IPv6 disabled" || echo "[!] IPv6 failed"

# DNS via TCP
setprop net.dns1 8.8.8.8
setprop net.dns2 8.8.4.4
iptables -t nat -C OUTPUT -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2>/dev/null || \
    iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2>/dev/null
iptables -t nat -C OUTPUT -p tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2>/dev/null || \
    iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2>/dev/null
echo "[+] DNS via TCP"
