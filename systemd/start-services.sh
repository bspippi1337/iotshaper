#!/data/data/com.termux/files/usr/bin/bash
# Termux:Boot autostart script
# Place in ~/.termux/boot/

REPO_DIR="$HOME/iot-data-shaper"

sleep 15

tsu -c "bash $REPO_DIR/config/apn-config.sh"
tsu -c "bash $REPO_DIR/config/network-tweaks.sh"
tsu -c "bash $REPO_DIR/config/firewall-rules.sh"

bash "$REPO_DIR/scripts/data-monitor.sh"

while true; do
    bash "$REPO_DIR/scripts/background-sync.sh" flush
    sleep 900
done
