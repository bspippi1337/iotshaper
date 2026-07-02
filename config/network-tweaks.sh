#!/system/bin/sh
# Universal Network Tweaks - handles missing kernel features

echo "[*] Detecting active mobile interface..."

# Method 1: Find UP mobile interface (most reliable)
IFACE=$(ip link show 2>/dev/null | grep -E 'ccmni[0-9]+:|rmnet_data[0-9]+:|rmnet[0-9]+:' | grep 'UP,LOWER_UP' | grep -v 'wlan\|lo\|dummy\|ifb\|tun\|gre\|sit' | head -1 | awk -F: '{print $2}' | awk '{print $1}')

# Method 2: Interface with IP
[ -z "$IFACE" ] && IFACE=$(ip addr show 2>/dev/null | grep -B2 'inet ' | grep -E 'ccmni[0-9]+:|rmnet_data[0-9]+:|rmnet[0-9]+:' | grep -v 'wlan\|lo' | head -1 | awk -F: '{print $2}' | awk '{print $1}')

# Method 3: Default route (exclude wlan)
[ -z "$IFACE" ] && IFACE=$(ip route 2>/dev/null | grep default | awk '{print $5}' | grep -v 'wlan\|lo' | head -1)

# Method 4: Active RX bytes
[ -z "$IFACE" ] && IFACE=$(for i in /sys/class/net/ccmni*/statistics/rx_bytes 2>/dev/null; do [ -f "$i" ] && [ "$(cat $i 2>/dev/null)" -gt 0 ] 2>/dev/null && basename $(dirname $i) && break; done)

# Method 5: Fallbacks
[ -z "$IFACE" ] && IFACE="ccmni1"
[ -z "$IFACE" ] && IFACE="ccmni0"
[ -z "$IFACE" ] && IFACE="rmnet_data0"
[ -z "$IFACE" ] && IFACE="eth0"

echo "[*] Interface: $IFACE"

# Verify
if ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "[!] $IFACE not found, trying any available..."
    IFACE=$(ls /sys/class/net/ 2>/dev/null | grep -E 'ccmni|rmnet|eth' | grep -v 'wlan\|lo' | head -1)
    [ -z "$IFACE" ] && { echo "[!] No suitable interface found"; exit 1; }
    echo "[*] Fallback: $IFACE"
fi

# Cache
echo "$IFACE" > /data/local/tmp/iotshaper_iface 2>/dev/null

# MTU
ip link set dev "$IFACE" mtu 1280 2>/dev/null && echo "[+] MTU=1280" || echo "[!] MTU failed (may need root)"

# TTL - check if TTL target exists first
if iptables -t mangle -A POSTROUTING -o "$IFACE" -j TTL --ttl-set 65 2>/dev/null; then
    # Remove the test rule and add proper one
    iptables -t mangle -D POSTROUTING -o "$IFACE" -j TTL --ttl-set 65 2>/dev/null
    iptables -t mangle -A POSTROUTING -o "$IFACE" -j TTL --ttl-set 65 2>/dev/null
    echo "[+] TTL=65"
else
    echo "[!] TTL target not supported by kernel, skipping"
fi

# TCP optimizations - only if files exist
for f in /proc/sys/net/ipv4/tcp_fastopen /proc/sys/net/ipv4/tcp_timestamps /proc/sys/net/ipv4/tcp_sack /proc/sys/net/ipv4/tcp_window_scaling /proc/sys/net/ipv4/tcp_keepalive_time /proc/sys/net/ipv4/tcp_keepalive_probes /proc/sys/net/ipv4/tcp_keepalive_intvl; do
    [ -f "$f" ] && echo 0 > "$f" 2>/dev/null || true
done
# Set fastopen and sack to 1 (enable)
[ -f /proc/sys/net/ipv4/tcp_fastopen ] && echo 3 > /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null || true
[ -f /proc/sys/net/ipv4/tcp_sack ] && echo 1 > /proc/sys/net/ipv4/tcp_sack 2>/dev/null || true
echo "[+] TCP optimized (best effort)"

# IPv6
[ -f /proc/sys/net/ipv6/conf/all/disable_ipv6 ] && { echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null && echo "[+] IPv6 disabled" || echo "[!] IPv6 failed"; } || echo "[!] IPv6 sysctl not available"

# DNS
setprop net.dns1 8.8.8.8
setprop net.dns2 8.8.4.4
iptables -t nat -C OUTPUT -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2>/dev/null || \
    iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2>/dev/null
iptables -t nat -C OUTPUT -p tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2>/dev/null || \
    iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2>/dev/null
echo "[+] DNS via TCP"
