#!/system/bin/sh
# Universal Firewall - Works with any interface

echo "[*] Detecting active interface..."

# Read cached interface or detect
IFACE=$(cat /data/local/tmp/iotshaper_iface 2>/dev/null)
[ -z "$IFACE" ] && IFACE=$(ip link show | grep -E '(ccmni[0-9]+|rmnet_data[0-9]+|rmnet[0-9]+|eth[0-9]+):.*UP,LOWER_UP' | grep -v 'wlan\|lo\|dummy\|ifb\|tun\|gre\|sit' | head -1 | awk -F: '{print $2}' | awk '{print $1}')
[ -z "$IFACE" ] && IFACE=$(ip addr show | grep -B2 'inet ' | grep -E '(ccmni[0-9]+|rmnet_data[0-9]+|rmnet[0-9]+|eth[0-9]+):' | grep -v 'wlan\|lo' | head -1 | awk -F: '{print $2}' | awk '{print $1}')
[ -z "$IFACE" ] && IFACE=$(ip route | grep default | awk '{print $5}' | grep -v 'wlan\|lo' | head -1)
[ -z "$IFACE" ] && IFACE="ccmni1"
[ -z "$IFACE" ] && IFACE="rmnet_data0"
[ -z "$IFACE" ] && IFACE="eth0"

echo "[*] Selected interface: $IFACE"

if ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "[!] Interface $IFACE not found"
    exit 1
fi

echo "[*] Applying firewall rules..."

# Flush existing
iptables -F 2>/dev/null
iptables -t mangle -F 2>/dev/null
iptables -t nat -F 2>/dev/null

# Block Google/telemetry (saves significant data)
iptables -A OUTPUT -d 216.58.0.0/16 -j DROP 2>/dev/null
iptables -A OUTPUT -d 172.217.0.0/16 -j DROP 2>/dev/null
iptables -A OUTPUT -d 151.101.0.0/16 -j DROP 2>/dev/null
iptables -A OUTPUT -p tcp --dport 5228 -j DROP 2>/dev/null   # GCM
iptables -A OUTPUT -p tcp --dport 5229 -j DROP 2>/dev/null   # Google
iptables -A OUTPUT -p tcp --dport 80 -m string --string "play.googleapis.com" --algo bm -j DROP 2>/dev/null
iptables -A OUTPUT -p tcp --dport 443 -m string --string "android.clients.google.com" --algo bm -j DROP 2>/dev/null

# Rate limiting to prevent burst counting
iptables -A INPUT -p tcp --syn -m limit --limit 1/second --limit-burst 3 -j ACCEPT 2>/dev/null
iptables -A INPUT -p tcp --syn -j DROP 2>/dev/null
iptables -A OUTPUT -o "$IFACE" -m limit --limit 50/minute --limit-burst 100 -j ACCEPT 2>/dev/null
iptables -A OUTPUT -o "$IFACE" -j DROP 2>/dev/null

# Prioritize Datacake API traffic
iptables -t mangle -A OUTPUT -d api.datacake.co -j MARK --set-mark 10 2>/dev/null

# Traffic shaping
tc qdisc add dev "$IFACE" root handle 1: htb default 20 2>/dev/null
tc class add dev "$IFACE" parent 1: classid 1:10 htb rate 50kbit ceil 100kbit 2>/dev/null
tc class add dev "$IFACE" parent 1: classid 1:20 htb rate 1kbit ceil 5kbit 2>/dev/null
tc filter add dev "$IFACE" protocol ip parent 1:0 prio 1 handle 10 fw flowid 1:10 2>/dev/null

echo "[+] Firewall active on $IFACE"
