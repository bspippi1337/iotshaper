#!/data/data/com.termux/files/usr/bin/bash
# Flush queued payloads to persistent local log

QUEUE_DIR="$HOME/iot-data-shaper/queue"
LOG_DIR="$HOME/iot-data-shaper/logs"
PERSISTENT_LOG="$LOG_DIR/payloads.jsonl"

mkdir -p "$LOG_DIR"

[ -z "$(ls -A $QUEUE_DIR 2>/dev/null)" ] && { echo "[*] Queue empty"; return; }

echo "[*] Flushing $(ls $QUEUE_DIR/*.json 2>/dev/null | wc -l) payloads to $PERSISTENT_LOG..."

for f in "$QUEUE_DIR"/*.json; do
    [ -f "$f" ] || continue
    cat "$f" >> "$PERSISTENT_LOG"
    echo "" >> "$PERSISTENT_LOG"
    rm "$f"
done

echo "[+] Flushed to $PERSISTENT_LOG"
echo "[*] Total lines: $(wc -l < "$PERSISTENT_LOG" 2>/dev/null || echo 0)"
