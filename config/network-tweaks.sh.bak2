#!/system/bin/sh
# Network Stack Optimization for Minimal Countable Data
# Run as root

IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
[ -z "$IFACE" ] && IFACE="rmnet_data0"

echo "[*] Tweaking $IFACE..."

ip link set dev "$IFACE" mtu 1280
echo "[+] MTU=1280"

iptables -t mangle -A POSTROUTING -o "$IFACE" -j TTL --ttl-set 65
echo "[+] TTL=65"

echo 3 > /proc/sys/net/ipv4/tcp_fastopen
echo 4096 > /proc/sys/net/ipv4/tcp_rmem_min
echo 4096 > /proc/sys/net/ipv4/tcp_wmem_min
echo 0 > /proc/sys/net/ipv4/tcp_timestamps
echo 1 > /proc/sys/net/ipv4/tcp_sack
echo 0 > /proc/sys/net/ipv4/tcp_window_scaling
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_time
echo 3 > /proc/sys/net/ipv4/tcp_keepalive_probes
echo 5 > /proc/sys/net/ipv4/tcp_keepalive_intvl

echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
echo "[+] IPv6 disabled"

setprop net.dns1 8.8.8.8
setprop net.dns2 8.8.4.4
iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53
iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53
echo "[+] DNS routed via TCP"
