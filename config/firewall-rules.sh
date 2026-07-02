#!/system/bin/sh
# Universal Firewall - handles missing features gracefully

echo "[*] Detecting interface..."

IFACE=$(cat /data/local/tmp/iotshaper_iface 2>/dev/null)
[ -z "$IFACE" ] && IFACE=$(ip link show 2>/dev/null | grep -E 'ccmni[0-9]+:|rmnet_data[0-9]+:|rmnet[0-9]+:' | grep 'UP,LOWER_UP' | grep -v 'wlan\|lo\|dummy\|ifb\|tun\|gre\|sit' | head -1 | awk -F: '{print $2}' | awk '{print $1}')
[ -z "$IFACE" ] && IFACE=$(ip addr show 2>/dev/null | grep -B2 'inet ' | grep -E 'ccmni[0-9]+:|rmnet_data[0-9]+:|rmnet[0-9]+:' | grep -v 'wlan\|lo' | head -1 | awk -F: '{print $2}' | awk '{print $1}')
[ -z "$IFACE" ] && IFACE=$(ip route 2>/dev/null | grep default | awk '{print $5}' | grep -v 'wlan\|lo' | head -1)
[ -z "$IFACE" ] && IFACE="ccmni1"
[ -z "$IFACE" ] && IFACE="rmnet_data0"
[ -z "$IFACE" ] && IFACE="eth0"

echo "[*] Interface: $IFACE"

if ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "[!] $IFACE not found"; exit 1
fi

echo "[*] Applying firewall..."

iptables -F 2>/dev/null
iptables -t mangle -F 2>/dev/null
iptables -t nat -F 2>/dev/null

# Block telemetry
iptables -A OUTPUT -d 216.58.0.0/16 -j DROP 2>/dev/null || true
iptables -A OUTPUT -d 172.217.0.0/16 -j DROP 2>/dev/null || true
iptables -A OUTPUT -d 151.101.0.0/16 -j DROP 2>/dev/null || true
iptables -A OUTPUT -p tcp --dport 5228 -j DROP 2>/dev/null || true
iptables -A OUTPUT -p tcp --dport 5229 -j DROP 2>/dev/null || true
iptables -A OUTPUT -p tcp --dport 80 -m string --string "play.googleapis.com" --algo bm -j DROP 2>/dev/null || true
iptables -A OUTPUT -p tcp --dport 443 -m string --string "android.clients.google.com" --algo bm -j DROP 2>/dev/null || true

# Rate limit
iptables -A INPUT -p tcp --syn -m limit --limit 1/second --limit-burst 3 -j ACCEPT 2>/dev/null || true
iptables -A INPUT -p tcp --syn -j DROP 2>/dev/null || true
iptables -A OUTPUT -o "$IFACE" -m limit --limit 50/minute --limit-burst 100 -j ACCEPT 2>/dev/null || true
iptables -A OUTPUT -o "$IFACE" -j DROP 2>/dev/null || true

# Traffic shaping (best effort)
tc qdisc add dev "$IFACE" root handle 1: htb default 20 2>/dev/null || true
tc class add dev "$IFACE" parent 1: classid 1:10 htb rate 50kbit ceil 100kbit 2>/dev/null || true
tc class add dev "$IFACE" parent 1: classid 1:20 htb rate 1kbit ceil 5kbit 2>/dev/null || true
tc filter add dev "$IFACE" protocol ip parent 1:0 prio 1 handle 10 fw flowid 1:10 2>/dev/null || true

echo "[+] Firewall active on $IFACE"
