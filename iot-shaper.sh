#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# IoT Data Shaper - Universal Edition
# Supports: EMnify, Telenor (all regions), Telenor XCN, generic IoT SIMs
# ============================================================================

REPO_DIR="$HOME/iot-data-shaper"
CONFIG_DIR="$REPO_DIR/config"
SCRIPT_DIR="$REPO_DIR/scripts"
LOG_DIR="$REPO_DIR/logs"
QUEUE_DIR="$REPO_DIR/queue"

case "$1" in
    install)
        echo "[*] Installing IoT Data Shaper (Universal Edition)"
        mkdir -p "$CONFIG_DIR" "$SCRIPT_DIR" "$LOG_DIR" "$QUEUE_DIR"

        echo ""
        echo "=== Datacake Configuration ==="
        echo "Get API Token from: https://app.datacake.co"
        read -p "Enter Datacake API Token: " token_input
        read -p "Enter Datacake Device Serial: " device_input

        cat > "$SCRIPT_DIR/datacake-config.sh" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
DATACAKE_TOKEN="$token_input"
DATACAKE_DEVICE="$device_input"
DATACAKE_API="https://api.datacake.co/integrations/api/v1"
EOF

        echo "[+] Config saved"
        echo "[*] Run 'bash iot-shaper.sh apply' (as root) to activate"
        ;;

    apply)
        if ! su -c "id" >/dev/null 2>&1; then
            echo "[!] Root required"
            exit 1
        fi
        echo "[*] Applying universal tweaks..."
        su -c "bash $CONFIG_DIR/apn-config.sh"
        su -c "bash $CONFIG_DIR/network-tweaks.sh"
        su -c "bash $CONFIG_DIR/firewall-rules.sh"
        echo "[+] All tweaks applied"
        ;;

    monitor) bash "$SCRIPT_DIR/data-monitor.sh" ;;
    ttl) bash "$SCRIPT_DIR/ttl-spoof.sh" "$2" ;;
    queue) bash "$SCRIPT_DIR/background-sync.sh" queue "$2" ;;
    flush) bash "$SCRIPT_DIR/background-sync.sh" flush ;;
    compress) bash "$SCRIPT_DIR/compress-payload.sh" "$2" "$3" ;;
    *)
        echo "IoT Data Shaper - Universal Edition"
        echo "Usage: bash $0 {install|apply|monitor|ttl|queue|flush|compress}"
        ;;
esac
