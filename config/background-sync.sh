#!/data/data/com.termux/files/usr/bin/bash
# Background Sync with Compression
# Queues data and sends in compressed batches during "off-peak"

QUEUE_DIR="$HOME/iot-data-shaper/queue"
mkdir -p "$QUEUE_DIR"

IOT_ENDPOINT="https://your-server.com/api/ingest"
COMPRESS_LEVEL=9  # Maximum gzip compression

queue_payload() {
    local payload="$1"
    local timestamp=$(date +%s)
    echo "$payload" > "$QUEUE_DIR/$timestamp.json"
    echo "[+] Queued payload for batch send"
}

flush_queue() {
    if [ -z "$(ls -A $QUEUE_DIR)" ]; then
        echo "[*] Queue empty"
        return
    fi

    # Combine all queued items
    COMBINED="$QUEUE_DIR/batch_$(date +%s).json"
    echo "[" > "$COMBINED"
    first=true
    for f in "$QUEUE_DIR"/*.json; do
        [ "$f" = "$COMBINED" ] && continue
        [ "$first" = true ] || echo "," >> "$COMBINED"
        cat "$f" >> "$COMBINED"
        first=false
        rm "$f"
    done
    echo "]" >> "$COMBINED"

    # Compress and send
    gzip -c "$COMBINED" > "$COMBINED.gz"
    
    # Send with minimal headers
    curl -s -X POST \
        -H "Content-Encoding: gzip" \
        -H "Content-Type: application/json" \
        --data-binary "@$COMBINED.gz" \
        --connect-timeout 10 \
        --max-time 30 \
        "$IOT_ENDPOINT" && rm "$COMBINED" "$COMBINED.gz"
}

case "$1" in
    queue) queue_payload "$2" ;;
    flush) flush_queue ;;
    *) echo "Usage: $0 {queue '<json>'|flush}" ;;
esac