#!/data/data/com.termux/files/usr/bin/bash
# Data Usage Monitor with <50MB Alert
# Run every 5 minutes via cron

LOG_DIR="$HOME/iot-data-shaper/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/usage.log"
ALERT_FILE="$LOG_DIR/alert.flag"

# Threshold in bytes (50MB)
THRESHOLD=$((50 * 1024 * 1024))

# Get current interface stats
IFACE=$(su -c "ip route | grep default | awk '{print \$5}' | head -1")
[ -z "$IFACE" ] && IFACE="rmnet_data0"

# Read RX/TX bytes from sysfs
RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
TOTAL=$((RX + TX))

# Convert to MB
TOTAL_MB=$((TOTAL / 1024 / 1024))
RX_MB=$((RX / 1024 / 1024))
TX_MB=$((TX / 1024 / 1024))

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Log
echo "$TIMESTAMP | RX: ${RX_MB}MB | TX: ${TX_MB}MB | TOTAL: ${TOTAL_MB}MB" >> "$LOG_FILE"

# Alert if approaching limit
if [ "$TOTAL" -gt "$THRESHOLD" ]; then
    if [ ! -f "$ALERT_FILE" ]; then
        echo "$TIMESTAMP | ALERT: 50MB threshold exceeded!" >> "$LOG_FILE"
        touch "$ALERT_FILE"
        # Optional: termux-notification
        termux-notification --title "IoT Data Alert" --content "50MB limit reached!" 2>/dev/null
    fi
fi

# Output current status for manual runs
echo "Interface: $IFACE"
echo "Download:  ${RX_MB}MB"
echo "Upload:    ${TX_MB}MB"
echo "Total:     ${TOTAL_MB}MB / 50MB"
echo "Remaining: $((50 - TOTAL_MB))MB"