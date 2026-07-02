#!/data/data/com.termux/files/usr/bin/bash
# IoT Data Shaper - Universal Edition (Local Log)
# Fixed: handles missing kernel modules, SELinux, wrong interfaces

REPO_DIR="$HOME/iot-data-shaper"
CONFIG_DIR="$REPO_DIR/config"
SCRIPT_DIR="$REPO_DIR/scripts"

case "$1" in
    install)
        echo "[*] Installing IoT Data Shaper"
        mkdir -p "$CONFIG_DIR" "$SCRIPT_DIR" "$REPO_DIR/logs" "$REPO_DIR/queue"
        echo "[+] Installed to $REPO_DIR"
        echo "[*] Run 'bash iot-shaper.sh apply' (as root)"
        ;;
    apply)
        if ! su -c "id" >/dev/null 2>&1; then echo "[!] Root required"; exit 1; fi
        echo "[*] Applying tweaks..."
        su -c "sh $CONFIG_DIR/apn-config.sh"
        su -c "sh $CONFIG_DIR/network-tweaks.sh"
        su -c "sh $CONFIG_DIR/firewall-rules.sh"
        echo "[+] Done"
        ;;
    monitor) bash "$SCRIPT_DIR/data-monitor.sh" ;;
    ttl) bash "$SCRIPT_DIR/ttl-spoof.sh" "$2" ;;
    queue) bash "$SCRIPT_DIR/queue-log.sh" "$2" ;;
    flush) bash "$SCRIPT_DIR/flush-log.sh" ;;
    compress) bash "$SCRIPT_DIR/compress-payload.sh" "$2" "$3" ;;
    status) bash "$SCRIPT_DIR/status.sh" ;;
    *)
        echo "Usage: bash $0 {install|apply|monitor|ttl|queue|flush|compress|status}"
        ;;
esac
