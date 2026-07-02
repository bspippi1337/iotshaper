#!/data/data/com.termux/files/usr/bin/bash
# Termux:Boot autostart script
# Place in ~/.termux/boot/

REPO_DIR="$HOME/iot-data-shaper"

# Wait for network
sleep 15

# Apply all tweaks
tsu -c "bash $REPO_DIR/config/apn-config.sh"
tsu -c "bash $REPO_DIR/config/network-tweaks.sh"
tsu -c "bash $REPO_DIR/config/firewall-rules.sh"

# Start monitoring
bash "$REPO_DIR/scripts/data-monitor.sh"

# Schedule queue flushes every 15 minutes
while true; do
    bash "$REPO_DIR/scripts/background-sync.sh" flush
    sleep 900
done