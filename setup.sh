#!/data/data/com.termux/files/usr/bin/bash
# IoT Data Shaper - Setup Script
# Run: bash setup.sh

set -e

TERMUX_PREFIX="/data/data/com.termux/files/usr"
REPO_DIR="$HOME/iot-data-shaper"
CONFIG_DIR="$REPO_DIR/config"
SCRIPT_DIR="$REPO_DIR/scripts"

echo "[*] IoT Data Shaper Setup for EMnify"
echo "[*] Target: <50MB countable data/month"

# Create directories
mkdir -p "$CONFIG_DIR" "$SCRIPT_DIR" "$REPO_DIR/logs"

# Install required packages
echo "[*] Installing dependencies..."
pkg update -y
pkg install -y root-repo
pkg install -y \
    iptables \
    nftables \
    curl \
    tcpdump \
    net-tools \
    iproute2 \
    dnsutils \
    busybox \
    zlib \
    openssl-tool \
    tsu

# Verify root access
if ! su -c "id" >/dev/null 2>&1; then
    echo "[!] Root access required. Ensure phone is rooted."
    exit 1
fi

# Apply all configurations
echo "[*] Applying network tweaks..."
su -c "bash $CONFIG_DIR/apn-config.sh"
su -c "bash $CONFIG_DIR/network-tweaks.sh"
su -c "bash $CONFIG_DIR/firewall-rules.sh"

# Install monitoring cron
echo "[*] Setting up data monitor..."
(crontab -l 2>/dev/null; echo "*/5 * * * * bash $SCRIPT_DIR/data-monitor.sh >> $REPO_DIR/logs/monitor.log 2>&1") | crontab -

echo "[+] Setup complete. Reboot recommended."
echo "[*] Run 'bash $SCRIPT_DIR/data-monitor.sh' to check usage."