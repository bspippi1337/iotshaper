#!/data/data/com.termux/files/usr/bin/bash
# Background Sync with Datacake

QUEUE_DIR="$HOME/iot-data-shaper/queue"
mkdir -p "$QUEUE_DIR"
source "$HOME/iot-data-shaper/scripts/datacake-config.sh"

queue_payload() {
    local payload="$1"
    local ts=$(date +%s)
    echo "$payload" > "$QUEUE_DIR/$ts.json"
    echo "[+] Queued payload (ts=$ts)"
}

flush_queue() {
    [ -z "$(ls -A $QUEUE_DIR)" ] && { echo "[*] Queue empty"; return; }
    echo "[*] Sending to Datacake..."
    for f in "$QUEUE_DIR"/*.json; do
        [ -f "$f" ] || continue
        curl -s -X POST \
            -H "Authorization: Token $DATACAKE_TOKEN" \
            -H "Content-Type: application/json" \
            -d "@$f" \
            --connect-timeout 10 \
            --max-time 30 \
            "$DATACAKE_API/devices/$DATACAKE_DEVICE/data/" && rm "$f"
        sleep 1
    done
    echo "[+] Flush complete"
}

case "$1" in
    queue) queue_payload "$2" ;;
    flush) flush_queue ;;
    *) echo "Usage: {queue '<json>'|flush}" ;;
esac
