#!/data/data/com.termux/files/usr/bin/bash
# Background Sync with Compression

QUEUE_DIR="$HOME/iot-data-shaper/queue"
mkdir -p "$QUEUE_DIR"
IOT_ENDPOINT="https://your-server.com/api/ingest"

queue_payload() { echo "$1" > "$QUEUE_DIR/$(date +%s).json"; echo "[+] Queued"; }

flush_queue() {
    [ -z "$(ls -A $QUEUE_DIR)" ] && { echo "[*] Queue empty"; return; }
    COMBINED="$QUEUE_DIR/batch_$(date +%s).json"
    echo "[" > "$COMBINED"; first=true
    for f in "$QUEUE_DIR"/*.json; do
        [ "$f" = "$COMBINED" ] && continue
        [ "$first" = true ] || echo "," >> "$COMBINED"
        cat "$f" >> "$COMBINED"; first=false; rm "$f"
    done
    echo "]" >> "$COMBINED"; gzip -c "$COMBINED" > "$COMBINED.gz"
    curl -s -X POST -H "Content-Encoding: gzip" -H "Content-Type: application/json" --data-binary "@$COMBINED.gz" --connect-timeout 10 --max-time 30 "$IOT_ENDPOINT" && rm "$COMBINED" "$COMBINED.gz"
}

case "$1" in queue) queue_payload "$2" ;; flush) flush_queue ;; *) echo "Usage: {queue '<json>'|flush}" ;; esac
