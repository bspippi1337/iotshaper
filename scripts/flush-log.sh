#!/data/data/com.termux/files/usr/bin/bash
QUEUE_DIR="$HOME/iot-data-shaper/queue"
LOG_DIR="$HOME/iot-data-shaper/logs"
PERSISTENT_LOG="$LOG_DIR/payloads.jsonl"
mkdir -p "$LOG_DIR"
[ -z "$(ls -A $QUEUE_DIR 2>/dev/null)" ] && { echo "[*] Queue empty"; return; }
echo "[*] Flushing $(ls $QUEUE_DIR/*.json 2>/dev/null | wc -l) payloads..."
for f in "$QUEUE_DIR"/*.json; do [ -f "$f" ] || continue; cat "$f" >> "$PERSISTENT_LOG"; echo "" >> "$PERSISTENT_LOG"; rm "$f"; done
echo "[+] Flushed to $PERSISTENT_LOG"
