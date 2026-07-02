#!/data/data/com.termux/files/usr/bin/bash
# Show system status

echo "=== IoT Data Shaper Status ==="
echo ""

# Interface
IFACE=$(cat /data/local/tmp/iotshaper_iface 2>/dev/null)
[ -z "$IFACE" ] && IFACE=$(su -c "ip link show | grep -E 'ccmni[0-9]+|rmnet_data[0-9]+|rmnet[0-9]+|eth[0-9]+' | grep 'UP,LOWER_UP' | grep -v 'wlan\|lo' | head -1 | awk -F: '{print \$2}' | awk '{print \$1}'")
echo "Interface: ${IFACE:-unknown}"

# Carrier
MCCMNC=$(getprop gsm.sim.operator.numeric 2>/dev/null)
OPERATOR=$(getprop gsm.sim.operator.alpha 2>/dev/null)
echo "Carrier: ${OPERATOR:-unknown} (${MCCMNC:-unknown})"

# Data state
if dumpsys telephony.registry 2>/dev/null | grep -q 'mDataConnectionState=2'; then
    echo "Data: CONNECTED"
else
    echo "Data: DISCONNECTED or CONNECTING"
fi

# MTU
if [ -n "$IFACE" ]; then
    CURRENT_MTU=$(cat /sys/class/net/$IFACE/mtu 2>/dev/null)
    echo "MTU: ${CURRENT_MTU:-unknown}"
fi

# TTL rules
if iptables -t mangle -L POSTROUTING 2>/dev/null | grep -q 'TTL'; then
    echo "TTL: SET"
else
    echo "TTL: NOT SET"
fi

# IPv6
IPV6=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null)
echo "IPv6: $([ "$IPV6" = "1" ] && echo 'DISABLED' || echo 'ENABLED')"

# Queue
QUEUE_DIR="$HOME/iot-data-shaper/queue"
QUEUE_COUNT=$(ls "$QUEUE_DIR"/*.json 2>/dev/null | wc -l)
echo "Queue: $QUEUE_COUNT payloads"

# Logs
LOG_DIR="$HOME/iot-data-shaper/logs"
echo "Logs: $(ls -lh "$LOG_DIR" 2>/dev/null | tail -n +2 | wc -l) files"
