#!/system/bin/sh
# Firewall Rules for Data Minimization
# Run as root

IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
[ -z "$IFACE" ] && IFACE="rmnet_data0"

echo "[*] Applying firewall on $IFACE..."

iptables -F; iptables -t mangle -F; iptables -t nat -F

iptables -A OUTPUT -d 216.58.0.0/16 -j DROP
iptables -A OUTPUT -d 172.217.0.0/16 -j DROP
iptables -A OUTPUT -d 151.101.0.0/16 -j DROP
iptables -A OUTPUT -p tcp --dport 5228 -j DROP
iptables -A OUTPUT -p tcp --dport 5229 -j DROP
iptables -A OUTPUT -p tcp --dport 80 -m string --string "play.googleapis.com" --algo bm -j DROP
iptables -A OUTPUT -p tcp --dport 443 -m string --string "android.clients.google.com" --algo bm -j DROP

iptables -A INPUT -p tcp --syn -m limit --limit 1/second --limit-burst 3 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

iptables -A OUTPUT -o "$IFACE" -m limit --limit 50/minute --limit-burst 100 -j ACCEPT
iptables -A OUTPUT -o "$IFACE" -j DROP

iptables -t mangle -A OUTPUT -d api.datacake.co -j MARK --set-mark 10

tc qdisc add dev "$IFACE" root handle 1: htb default 20 2>/dev/null
tc class add dev "$IFACE" parent 1: classid 1:10 htb rate 50kbit ceil 100kbit 2>/dev/null
tc class add dev "$IFACE" parent 1: classid 1:20 htb rate 1kbit ceil 5kbit 2>/dev/null
tc filter add dev "$IFACE" protocol ip parent 1:0 prio 1 handle 10 fw flowid 1:10 2>/dev/null

echo "[+] Firewall active"
