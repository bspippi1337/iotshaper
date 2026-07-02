#!/system/bin/sh
# Universal Network Tweaks - Works with any mobile interface

echo "[*] Detecting active mobile interface..."

# Priority 1: Find interface that is UP and has mobile data characteristics
# ccmni (MediaTek), rmnet (Qualcomm), eth (some devices), usb (tethering)
IFACE=$(ip link show | grep -E '(ccmni[0-9]+|rmnet_data[0-9]+|rmnet[0-9]+|eth[0-9]+):.*UP,LOWER_UP' | grep -v 'wlan\|lo\|dummy\|ifb\|tun\|gre\|sit' | head -1 | awk -F: '{print $2}' | awk '{print $1}')

# Priority 2: Interface with IP but not WiFi
[ -z "$IFACE" ] && IFACE=$(ip addr show | grep -B2 'inet ' | grep -E '(ccmni[0-9]+|rmnet_data[0-9]+|rmnet[0-9]+|eth[0-9]+):' | grep -v 'wlan\|lo' | head -1 | awk -F: '{print $2}' | awk '{print $1}')

# Priority 3: Default route interface
[ -z "$IFACE" ] && IFACE=$(ip route | grep default | awk '{print $5}' | grep -v 'wlan\|lo' | head -1)

# Priority 4: Check which ccmni has data activity
[ -z "$IFACE" ] && IFACE=$(for i in /sys/class/net/ccmni*/statistics/rx_bytes 2>/dev/null; do [ -f "$i" ] && [ "$(cat $i)" -gt 0 ] 2>/dev/null && basename $(dirname $i) && break; done)

# Priority 5: Hardcoded fallbacks (most common)
[ -z "$IFACE" ] && IFACE="ccmni1"    # MediaTek data
[ -z "$IFACE" ] && IFACE="ccmni0"    # MediaTek fallback
[ -z "$IFACE" ] && IFACE="rmnet_data0" # Qualcomm
[ -z "$IFACE" ] && IFACE="eth0"      # Generic fallback

echo "[*] Selected interface: $IFACE"

# Verify interface exists
if ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "[!] Interface $IFACE not found, trying any available..."
    IFACE=$(ls /sys/class/net/ | grep -E 'ccmni|rmnet|eth' | grep -v 'wlan' | head -1)
    [ -z "$IFACE" ] && { echo "[!] No suitable interface found"; exit 1; }
    echo "[*] Fallback interface: $IFACE"
fi

# Save interface for other scripts
echo "$IFACE" > /data/local/tmp/iotshaper_iface 2>/dev/null

# MTU optimization
ip link set dev "$IFACE" mtu 1280 2>/dev/null && echo "[+] MTU=1280 on $IFACE" || echo "[!] MTU set failed"

# TTL manipulation
iptables -t mangle -C POSTROUTING -o "$IFACE" -j TTL --ttl-set 65 2>/dev/null || \
    iptables -t mangle -A POSTROUTING -o "$IFACE" -j TTL --ttl-set 65 2>/dev/null
echo "[+] TTL=65"

# TCP optimizations
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

# IPv6 disable (saves data)
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null && echo "[+] IPv6 disabled" || echo "[!] IPv6 disable failed"

# DNS optimization - force TCP to bypass UDP counting
setprop net.dns1 8.8.8.8
setprop net.dns2 8.8.4.4
iptables -t nat -C OUTPUT -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2>/dev/null || \
    iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2>/dev/null
iptables -t nat -C OUTPUT -p tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2>/dev/null || \
    iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2>/dev/null
echo "[+] DNS routed via TCP"
