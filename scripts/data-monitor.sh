#!/data/data/com.termux/files/usr/bin/bash
# Data Usage Monitor with <50MB Alert

LOG_DIR="$HOME/iot-data-shaper/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/usage.log"
ALERT_FILE="$LOG_DIR/alert.flag"
THRESHOLD=$((50 * 1024 * 1024))

IFACE=$(su -c "ip route | grep default | awk '{print $5}' | head -1")
[ -z "$IFACE" ] && IFACE="rmnet_data0"

RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
TOTAL=$((RX + TX))

TOTAL_MB=$((TOTAL / 1024 / 1024))
RX_MB=$((RX / 1024 / 1024))
TX_MB=$((TX / 1024 / 1024))

TS=$(date '+%Y-%m-%d %H:%M:%S')
echo "$TS | RX:${RX_MB}MB TX:${TX_MB}MB TOTAL:${TOTAL_MB}MB" >> "$LOG_FILE"

[ "$TOTAL" -gt "$THRESHOLD" ] && [ ! -f "$ALERT_FILE" ] && { echo "$TS | ALERT: 50MB exceeded!" >> "$LOG_FILE"; touch "$ALERT_FILE"; termux-notification --title "IoT Alert" --content "50MB reached!" 2>/dev/null; }

echo "Interface: $IFACE"
echo "Download:  ${RX_MB}MB"
echo "Upload:    ${TX_MB}MB"
echo "Total:     ${TOTAL_MB}MB / 50MB"
echo "Remaining: $((50 - TOTAL_MB))MB"
