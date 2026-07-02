#!/data/data/com.termux/files/usr/bin/bash
# Setup Script - Local Log Edition
set -e

REPO_DIR="$HOME/iot-data-shaper"
mkdir -p "$REPO_DIR"/{config,scripts,logs,queue,systemd,docs}

echo "[*] Installing dependencies..."
pkg update -y
pkg install -y root-repo
pkg install -y iptables curl net-tools iproute2 dnsutils busybox tsu

if ! su -c "id" >/dev/null 2>&1; then
    echo "[!] Root access required. Ensure phone is rooted."
    exit 1
fi

echo "[*] Applying tweaks..."
su -c "sh $REPO_DIR/config/apn-config.sh"
su -c "sh $REPO_DIR/config/network-tweaks.sh"
su -c "sh $REPO_DIR/config/firewall-rules.sh"

echo "[*] Setting up monitor cron..."
(crontab -l 2>/dev/null; echo "*/5 * * * * bash $REPO_DIR/scripts/data-monitor.sh >> $REPO_DIR/logs/monitor.log 2>&1") | crontab -

echo "[+] Setup complete. Reboot recommended."
