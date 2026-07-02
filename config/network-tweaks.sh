#!/system/bin/sh
# Network Stack Optimization for Minimal Countable Data
# Run as root

IFACE=$(getprop net.dns1)  # Detect active interface
# Better detection:
IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
[ -z "$IFACE" ] && IFACE="rmnet_data0"  # Common mobile interface

echo "[*] Applying network tweaks on $IFACE..."

# ============================================
# MTU OPTIMIZATION
# ============================================
# Standard MTU is 1500, but mobile networks often fragment.
# Lower MTU = less overhead per packet, but more headers.
# Sweet spot for IoT: 1280 (minimum IPv6) or 1400
# EMnify uses GRE tunneling, so account for overhead:
#   IP header: 20 bytes
#   GRE header: 4-16 bytes  
#   Encryption overhead: 20-40 bytes
# Target effective payload: ~1350 bytes

MTU_SIZE="1280"             # Safe for all networks, minimal fragmentation
# MTU_SIZE="1400"           # Alternative if 1280 causes issues

ip link set dev "$IFACE" mtu "$MTU_SIZE"
echo "[+] MTU set to $MTU_SIZE on $IFACE"

# ============================================
# TTL MANIPULATION (Carrier Evasion)
# ============================================
# Carriers often count data based on TTL values.
# Standard OS TTL: Linux=64, Android=64, Windows=128, iOS=64
# By setting TTL=65 (or 129), we signal "tethered" traffic
# Some carriers don't count tethered data against plan
# OR set TTL=1 to make traffic appear local (experimental)

TTL_VALUE="65"              # Appears as tethered/hop traffic
# TTL_VALUE="1"             # Appears local (risky, may break routing)

iptables -t mangle -A POSTROUTING -o "$IFACE" -j TTL --ttl-set "$TTL_VALUE"
echo "[+] TTL set to $TTL_VALUE on outbound packets"

# Alternative: Randomize TTL to evade pattern detection
# iptables -t mangle -A POSTROUTING -o "$IFACE" -j TTL --ttl-set $((RANDOM % 30 + 60))

# ============================================
# TCP OPTIMIZATION
# ============================================
# Reduce TCP overhead, disable Nagle for small packets

# TCP Fast Open (reduce handshake overhead)
echo 3 > /proc/sys/net/ipv4/tcp_fastopen

# Smaller window = less buffering, more responsive
echo 4096 > /proc/sys/net/ipv4/tcp_rmem_min
echo 4096 > /proc/sys/net/ipv4/tcp_wmem_min

# Disable TCP timestamps (saves 12 bytes per packet, harder to fingerprint)
echo 0 > /proc/sys/net/ipv4/tcp_timestamps

# Enable TCP SACK (recover faster, less retransmission)
echo 1 > /proc/sys/net/ipv4/tcp_sack

# Disable TCP window scaling (saves options bytes)
echo 0 > /proc/sys/net/ipv4/tcp_window_scaling

# Keepalive intervals (detect dead connections faster)
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_time
echo 3 > /proc/sys/net/ipv4/tcp_keepalive_probes
echo 5 > /proc/sys/net/ipv4/tcp_keepalive_intvl

# ============================================
# IPV6 HARDENING (if not needed, disable)
# ============================================
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
echo "[+] IPv6 disabled (reduces overhead if not needed)"

# ============================================
# DNS OPTIMIZATION
# ============================================
# Use DNS over HTTPS/TLS to prevent ISP injection
# But for data counting: use minimal DNS, cache aggressively

# Local DNS cache via pdnsd or dnsmasq (install separately)
# Or use Google DNS (8.8.8.8) with TCP to bypass UDP counting
setprop net.dns1 8.8.8.8
setprop net.dns2 8.8.4.4

# Force DNS over TCP (some carriers don't count TCP DNS)
iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53
iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53

echo "[+] Network tweaks applied successfully"