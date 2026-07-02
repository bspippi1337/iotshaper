#!/data/data/com.termux/files/usr/bin/bash
# Queue payload to local log file

QUEUE_DIR="$HOME/iot-data-shaper/queue"
mkdir -p "$QUEUE_DIR"

payload="$1"
ts=$(date +%s)

# Save as JSON with timestamp
echo "{\"timestamp\":$ts,\"data\":$payload}" > "$QUEUE_DIR/$ts.json"
echo "[+] Queued payload (ts=$ts)"
