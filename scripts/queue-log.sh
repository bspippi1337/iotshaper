#!/data/data/com.termux/files/usr/bin/bash
QUEUE_DIR="$HOME/iot-data-shaper/queue"
mkdir -p "$QUEUE_DIR"
payload="$1"
ts=$(date +%s)
echo "{\"timestamp\":$ts,\"data\":$payload}" > "$QUEUE_DIR/$ts.json"
echo "[+] Queued (ts=$ts)"
