#!/data/data/com.termux/files/usr/bin/bash
echo "=== IoT Data Shaper Status ==="
IFACE=$(cat /data/local/tmp/iotshaper_iface 2>/dev/null)
[ -z "$IFACE" ] && IFACE=$(su -c "ip link show | grep -E 'ccmni[0-9]+:|rmnet_data[0-9]+:' | grep 'UP,LOWER_UP' | grep -v 'wlan\|lo' | head -1 | awk -F: '{print \$2}' | awk '{print \$1}'")
echo "Interface: ${IFACE:-unknown}"
MCCMNC=$(getprop gsm.sim.operator.numeric 2>/dev/null)
OPERATOR=$(getprop gsm.sim.operator.alpha 2>/dev/null)
echo "Carrier: ${OPERATOR:-unknown} (${MCCMNC:-unknown})"
dumpsys telephony.registry 2>/dev/null | grep -q 'mDataConnectionState=2' && echo "Data: CONNECTED" || echo "Data: DISCONNECTED/CONNECTING"
[ -n "$IFACE" ] && { CURRENT_MTU=$(cat /sys/class/net/$IFACE/mtu 2>/dev/null); echo "MTU: ${CURRENT_MTU:-unknown}"; }
iptables -t mangle -L POSTROUTING 2>/dev/null | grep -q 'TTL' && echo "TTL: SET" || echo "TTL: NOT SET"
IPV6=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null)
echo "IPv6: $([ "$IPV6" = "1" ] && echo 'DISABLED' || echo 'ENABLED')"
QUEUE_DIR="$HOME/iot-data-shaper/queue"
echo "Queue: $(ls "$QUEUE_DIR"/*.json 2>/dev/null | wc -l) payloads"
