#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# IoT Data Shaper - Universal Edition (Local Log)
# Supports: Any SIM, any interface, no cloud dependency
# ============================================================================

REPO_DIR="$HOME/iot-data-shaper"
CONFIG_DIR="$REPO_DIR/config"
SCRIPT_DIR="$REPO_DIR/scripts"
LOG_DIR="$REPO_DIR/logs"
QUEUE_DIR="$REPO_DIR/queue"

case "$1" in
    install)
        echo "[*] Installing IoT Data Shaper (Local Log Edition)"
        mkdir -p "$CONFIG_DIR" "$SCRIPT_DIR" "$LOG_DIR" "$QUEUE_DIR"
        echo "[+] Installed to $REPO_DIR"
        echo "[*] Run 'bash iot-shaper.sh apply' (as root) to activate"
        ;;

    apply)
        if ! su -c "id" >/dev/null 2>&1; then
            echo "[!] Root required. Phone must be rooted."
            exit 1
        fi
        echo "[*] Applying universal tweaks..."
        su -c "sh $CONFIG_DIR/apn-config.sh"
        su -c "sh $CONFIG_DIR/network-tweaks.sh"
        su -c "sh $CONFIG_DIR/firewall-rules.sh"
        echo "[+] All tweaks applied"
        ;;

    monitor) bash "$SCRIPT_DIR/data-monitor.sh" ;;
    ttl) bash "$SCRIPT_DIR/ttl-spoof.sh" "$2" ;;
    queue) bash "$SCRIPT_DIR/queue-log.sh" "$2" ;;
    flush) bash "$SCRIPT_DIR/flush-log.sh" ;;
    compress) bash "$SCRIPT_DIR/compress-payload.sh" "$2" "$3" ;;
    status) bash "$SCRIPT_DIR/status.sh" ;;
    *)
        echo "IoT Data Shaper - Local Log Edition"
        echo "Usage:"
        echo "  bash $0 install       # Extract scripts"
        echo "  bash $0 apply         # Apply tweaks (root)"
        echo "  bash $0 monitor       # Show data usage"
        echo "  bash $0 ttl [64|65|1|random|reset]"
        echo "  bash $0 queue '<json>' # Queue payload to local log"
        echo "  bash $0 flush         # Write queued data to persistent log"
        echo "  bash $0 compress '<json>' [gzip|brotli|lzma|minify]"
        echo "  bash $0 status        # Show system status"
        ;;
esac
