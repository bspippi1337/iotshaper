#!/system/bin/sh
# Firewall Rules for Data Minimization
# Run as root

IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
[ -z "$IFACE" ] && IFACE="rmnet_data0"

echo "[*] Configuring firewall rules..."

# Flush existing
iptables -F
iptables -t mangle -F
iptables -t nat -F

# ============================================
# BLOCK BACKGROUND DATA LEAKS
# ============================================

# Block common analytics/telemetry domains at IP level
# (Supplement with hosts file blocking)

# Google telemetry
iptables -A OUTPUT -d 216.58.0.0/16 -j DROP  # Google (partial)
iptables -A OUTPUT -d 172.217.0.0/16 -j DROP  # Google (partial)

# Firebase, Crashlytics
iptables -A OUTPUT -d 151.101.0.0/16 -j DROP

# Block Android system telemetry
iptables -A OUTPUT -p tcp --dport 5228 -j DROP  # Google Cloud Messaging
iptables -A OUTPUT -p tcp --dport 5229 -j DROP

# Block app updates
iptables -A OUTPUT -p tcp --dport 80 -m string --string "play.googleapis.com" --algo bm -j DROP
iptables -A OUTPUT -p tcp --dport 443 -m string --string "android.clients.google.com" --algo bm -j DROP

# ============================================
# RATE LIMITING (Critical for <50MB)
# ============================================
# Limit burst traffic that carriers count aggressively

# Limit TCP SYN rate
iptables -A INPUT -p tcp --syn -m limit --limit 1/second --limit-burst 3 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

# Limit overall output rate on mobile interface
iptables -A OUTPUT -o "$IFACE" -m limit --limit 50/minute --limit-burst 100 -j ACCEPT
iptables -A OUTPUT -o "$IFACE" -j DROP

# ============================================
# PRIORITIZE IOT TRAFFIC
# ============================================
# Mark your IoT traffic as high priority, everything else low

# Mark IoT server IPs (replace with your endpoints)
IOT_SERVER="YOUR_SERVER_IP"
iptables -t mangle -A OUTPUT -d "$IOT_SERVER" -j MARK --set-mark 10

# Shape: IoT gets priority, everything else throttled
tc qdisc add dev "$IFACE" root handle 1: htb default 20
tc class add dev "$IFACE" parent 1: classid 1:10 htb rate 50kbit ceil 100kbit
tc class add dev "$IFACE" parent 1: classid 1:20 htb rate 1kbit ceil 5kbit
tc filter add dev "$IFACE" protocol ip parent 1:0 prio 1 handle 10 fw flowid 1:10

echo "[+] Firewall rules applied"