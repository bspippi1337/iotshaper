#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# IoT Data Shaper for EMnify - Single Self-Extracting Script
# ============================================================================
# Run: bash iot-shaper.sh install
#      bash iot-shaper.sh apply     (needs root)
#      bash iot-shaper.sh monitor   (live data usage)
#      bash iot-shaper.sh ttl 65    (set TTL)
#      bash iot-shaper.sh queue '<json>'
#      bash iot-shaper.sh flush
# ============================================================================

REPO_DIR="$HOME/iot-data-shaper"
CONFIG_DIR="$REPO_DIR/config"
SCRIPT_DIR="$REPO_DIR/scripts"
LOG_DIR="$REPO_DIR/logs"
QUEUE_DIR="$REPO_DIR/queue"

IOT_SERVER="YOUR_SERVER_IP"
IOT_ENDPOINT="https://your-server.com/api/ingest"

# ============================================================================
# INSTALL - Create directory structure and extract all scripts
# ============================================================================
install_all() {
    echo "[*] Installing IoT Data Shaper to $REPO_DIR"
    mkdir -p "$CONFIG_DIR" "$SCRIPT_DIR" "$LOG_DIR" "$QUEUE_DIR"

    # --- README.md ---
    cat > "$REPO_DIR/README.md" <<'DOC'
# IoT Data Shaper for EMnify

Target: <50MB countable data/month.

## Quick Start

```bash
bash iot-shaper.sh install   # Extract all scripts
bash iot-shaper.sh apply     # Apply network tweaks (root)
bash iot-shaper.sh monitor   # Check usage
```

## Commands

| Command | Description |
|---------|-------------|
| `install` | Create dirs and extract all scripts |
| `apply` | Apply APN + network + firewall tweaks (root) |
| `monitor` | Show live data usage |
| `ttl [64|65|1|random|reset]` | Change TTL mode |
| `queue '<json>'` | Queue a payload for batch send |
| `flush` | Send all queued payloads |
| `compress '<json>' [gzip|brotli|lzma|minify]` | Compress payload |

## Files

- `config/apn-config.sh` — EMnify APN + roaming
- `config/network-tweaks.sh` — MTU=1280, TTL=65, TCP opts
- `config/firewall-rules.sh` — Block telemetry, rate limit
- `scripts/ttl-spoof.sh` — TTL manipulation
- `scripts/data-monitor.sh` — Usage tracking
- `scripts/background-sync.sh` — Batch uploads
- `scripts/compress-payload.sh` — Payload compression
- `systemd/start-services.sh` — Termux:Boot autostart
- `docs/CARRIER-EVASION.md` — How carriers count data
- `docs/EMNIFY-SPECS.md` — EMnify reference
DOC

    # --- config/apn-config.sh ---
    cat > "$CONFIG_DIR/apn-config.sh" <<'APN'
#!/system/bin/sh
echo "[*] Configuring EMnify APN..."
APN_NAME="EMnify"; APN="em"; MCC="901"; MNC="43"
setprop gsm.operator.numeric "$MCC$MNC"
setprop gsm.sim.operator.numeric "$MCC$MNC"
setprop gsm.apn.sim.operator.numeric "$MCC$MNC"
APN_DB="/data/data/com.android.providers.telephony/databases/telephony.db"
if command -v sqlite3 >/dev/null; then
    sqlite3 "$APN_DB" "INSERT OR REPLACE INTO carriers (name,numeric,mcc,mnc,apn,type,current,protocol,roaming_protocol,carrier_enabled,bearer) VALUES ('$APN_NAME','$MCC$MNC','$MCC','$MNC','$APN','default,supl,dun',1,'IPV4V6','IPV4V6',1,0);"
fi
settings put global data_roaming1 1
settings put global data_roaming2 1
setprop ro.com.android.dataroaming true
settings put global roaming_indication_needed 0
svc data disable; sleep 2; svc data enable
sleep 3
echo "[+] Operator: $(getprop gsm.apn.sim.operator.numeric)"
echo "[+] Roaming: $(settings get global data_roaming1)"
APN

    # --- config/network-tweaks.sh ---
    cat > "$CONFIG_DIR/network-tweaks.sh" <<'NET'
#!/system/bin/sh
IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
[ -z "$IFACE" ] && IFACE="rmnet_data0"
echo "[*] Tweaking $IFACE..."
ip link set dev "$IFACE" mtu 1280
echo "[+] MTU=1280"
iptables -t mangle -A POSTROUTING -o "$IFACE" -j TTL --ttl-set 65
echo "[+] TTL=65"
echo 3 > /proc/sys/net/ipv4/tcp_fastopen
echo 4096 > /proc/sys/net/ipv4/tcp_rmem_min
echo 4096 > /proc/sys/net/ipv4/tcp_wmem_min
echo 0 > /proc/sys/net/ipv4/tcp_timestamps
echo 1 > /proc/sys/net/ipv4/tcp_sack
echo 0 > /proc/sys/net/ipv4/tcp_window_scaling
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_time
echo 3 > /proc/sys/net/ipv4/tcp_keepalive_probes
echo 5 > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
echo "[+] IPv6 disabled"
setprop net.dns1 8.8.8.8
setprop net.dns2 8.8.4.4
iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53
iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53
echo "[+] DNS routed via TCP"
NET

    # --- config/firewall-rules.sh ---
    cat > "$CONFIG_DIR/firewall-rules.sh" <<'FW'
#!/system/bin/sh
IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
[ -z "$IFACE" ] && IFACE="rmnet_data0"
echo "[*] Applying firewall on $IFACE..."
iptables -F; iptables -t mangle -F; iptables -t nat -F
iptables -A OUTPUT -d 216.58.0.0/16 -j DROP
iptables -A OUTPUT -d 172.217.0.0/16 -j DROP
iptables -A OUTPUT -d 151.101.0.0/16 -j DROP
iptables -A OUTPUT -p tcp --dport 5228 -j DROP
iptables -A OUTPUT -p tcp --dport 5229 -j DROP
iptables -A OUTPUT -p tcp --dport 80 -m string --string "play.googleapis.com" --algo bm -j DROP
iptables -A OUTPUT -p tcp --dport 443 -m string --string "android.clients.google.com" --algo bm -j DROP
iptables -A INPUT -p tcp --syn -m limit --limit 1/second --limit-burst 3 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP
iptables -A OUTPUT -o "$IFACE" -m limit --limit 50/minute --limit-burst 100 -j ACCEPT
iptables -A OUTPUT -o "$IFACE" -j DROP
IOT_SERVER="YOUR_SERVER_IP"
iptables -t mangle -A OUTPUT -d "$IOT_SERVER" -j MARK --set-mark 10
tc qdisc add dev "$IFACE" root handle 1: htb default 20 2>/dev/null
tc class add dev "$IFACE" parent 1: classid 1:10 htb rate 50kbit ceil 100kbit 2>/dev/null
tc class add dev "$IFACE" parent 1: classid 1:20 htb rate 1kbit ceil 5kbit 2>/dev/null
tc filter add dev "$IFACE" protocol ip parent 1:0 prio 1 handle 10 fw flowid 1:10 2>/dev/null
echo "[+] Firewall active"
FW

    # --- scripts/ttl-spoof.sh ---
    cat > "$SCRIPT_DIR/ttl-spoof.sh" <<'TTL'
#!/data/data/com.termux/files/usr/bin/bash
IFACE=$(su -c "ip route | grep default | awk '{print $5}' | head -1")
case "$1" in
    tether) su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set 64"; echo "[+] TTL=64 (tethered)" ;;
    local) su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set 1"; echo "[+] TTL=1 (local)" ;;
    random) su -c "iptables -t mangle -I POSTROUTING -o $IFACE -j TTL --ttl-set $((RANDOM % 20 + 60))"; echo "[+] TTL randomized" ;;
    reset) su -c "iptables -t mangle -F"; echo "[+] TTL reset" ;;
    *) echo "Usage: ttl {tether|local|random|reset}" ;;
esac
TTL

    # --- scripts/data-monitor.sh ---
    cat > "$SCRIPT_DIR/data-monitor.sh" <<'MON'
#!/data/data/com.termux/files/usr/bin/bash
LOG_DIR="$HOME/iot-data-shaper/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/usage.log"
ALERT_FILE="$LOG_DIR/alert.flag"
THRESHOLD=$((50 * 1024 * 1024))
IFACE=$(su -c "ip route | grep default | awk '{print $5}' | head -1")
[ -z "$IFACE" ] && IFACE="rmnet_data0"
RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
TOTAL=$((RX + TX))
TOTAL_MB=$((TOTAL / 1024 / 1024))
RX_MB=$((RX / 1024 / 1024))
TX_MB=$((TX / 1024 / 1024))
TS=$(date '+%Y-%m-%d %H:%M:%S')
echo "$TS | RX:${RX_MB}MB TX:${TX_MB}MB TOTAL:${TOTAL_MB}MB" >> "$LOG_FILE"
[ "$TOTAL" -gt "$THRESHOLD" ] && [ ! -f "$ALERT_FILE" ] && { echo "$TS | ALERT: 50MB exceeded!" >> "$LOG_FILE"; touch "$ALERT_FILE"; termux-notification --title "IoT Alert" --content "50MB reached!" 2>/dev/null; }
echo "Interface: $IFACE"
echo "Download:  ${RX_MB}MB"
echo "Upload:    ${TX_MB}MB"
echo "Total:     ${TOTAL_MB}MB / 50MB"
echo "Remaining: $((50 - TOTAL_MB))MB"
MON

    # --- scripts/background-sync.sh ---
    cat > "$SCRIPT_DIR/background-sync.sh" <<'SYNC'
#!/data/data/com.termux/files/usr/bin/bash
QUEUE_DIR="$HOME/iot-data-shaper/queue"
mkdir -p "$QUEUE_DIR"
IOT_ENDPOINT="https://your-server.com/api/ingest"
queue_payload() { echo "$1" > "$QUEUE_DIR/$(date +%s).json"; echo "[+] Queued"; }
flush_queue() {
    [ -z "$(ls -A $QUEUE_DIR)" ] && { echo "[*] Queue empty"; return; }
    COMBINED="$QUEUE_DIR/batch_$(date +%s).json"
    echo "[" > "$COMBINED"; first=true
    for f in "$QUEUE_DIR"/*.json; do [ "$f" = "$COMBINED" ] && continue; [ "$first" = true ] || echo "," >> "$COMBINED"; cat "$f" >> "$COMBINED"; first=false; rm "$f"; done
    echo "]" >> "$COMBINED"; gzip -c "$COMBINED" > "$COMBINED.gz"
    curl -s -X POST -H "Content-Encoding: gzip" -H "Content-Type: application/json" --data-binary "@$COMBINED.gz" --connect-timeout 10 --max-time 30 "$IOT_ENDPOINT" && rm "$COMBINED" "$COMBINED.gz"
}
case "$1" in queue) queue_payload "$2" ;; flush) flush_queue ;; *) echo "Usage: {queue '<json>'|flush}" ;; esac
SYNC

    # --- scripts/compress-payload.sh --- BUGFIXED
    cat > "$SCRIPT_DIR/compress-payload.sh" <<'COMP'
#!/data/data/com.termux/files/usr/bin/bash
PAYLOAD="$1"; METHOD="${2:-gzip}"
case "$METHOD" in
    gzip) echo "$PAYLOAD" | gzip -c -9 | base64 -w 0 ;;
    brotli) command -v brotli >/dev/null && echo "$PAYLOAD" | brotli -c -q 11 | base64 -w 0 || { echo "[!] No brotli, using gzip"; echo "$PAYLOAD" | gzip -c -9 | base64 -w 0; } ;;
    lzma) echo "$PAYLOAD" | xz -c -9e | base64 -w 0 ;;
    minify) echo "$PAYLOAD" | python3 -c "import sys,json; json.dump(json.load(sys.stdin), sys.stdout, separators=(',',':'))" 2>/dev/null | gzip -c -9 | base64 -w 0 ;;
esac
COMP

    # --- systemd/start-services.sh ---
    mkdir -p "$REPO_DIR/systemd"
    cat > "$REPO_DIR/systemd/start-services.sh" <<'BOOT'
#!/data/data/com.termux/files/usr/bin/bash
REPO_DIR="$HOME/iot-data-shaper"
sleep 15
tsu -c "bash $REPO_DIR/config/apn-config.sh"
tsu -c "bash $REPO_DIR/config/network-tweaks.sh"
tsu -c "bash $REPO_DIR/config/firewall-rules.sh"
bash "$REPO_DIR/scripts/data-monitor.sh"
while true; do bash "$REPO_DIR/scripts/background-sync.sh" flush; sleep 900; done
BOOT

    # --- docs/CARRIER-EVASION.md ---
    mkdir -p "$REPO_DIR/docs"
    cat > "$REPO_DIR/docs/CARRIER-EVASION.md" <<'DOC'
# Carrier Data Counting Evasion

## How Carriers Count Data
1. DPI — inspect headers, ports, protocols
2. TTL fingerprinting — Android=64, Windows=128, iOS=64
3. APN categorization — consumer vs machine data
4. Protocol analysis — HTTP/443 = user data

## TTL Strategy
| TTL | Appears As | Interpretation |
|-----|-----------|----------------|
| 64 | Standard Android | Normal user data |
| 65 | Tethered/hopped | Often exempt |
| 128 | Windows | Different profile |
| 1 | Local | May be dropped |

## MTU Optimization
Standard MTU=5000. Mobile adds GTP(xb)+IPsec(20-40b) = fragmentation.
Optimal IoT MTU=1280 — no fragmentation, less retransmission.

## Rules
1. Block telemetry
2. Rate limit bursts
3. Compress payloads (60-90%)
4. Batch uploads
5. UDP may count differently than TCP
DOC

    # --- docs/EMNIFY-SPECS.md ---
    cat > "$REPO_DIR/docs/EMNIFY-SPECS.md" <<'DOC'
# EMnify IoT SIM

## APN
| Param | Value |
|-------|-------|
| APN | `em` |
| User/Pass | (blank) |
| Auth | None (IMEI-based) |
| MCC/MNC | 901/43 |
| Protocol | IPv4v6 |

## Roaming
Required. Global SIM. No roaming charges.

## Data Plans
- Pay-per-use: ~$0.10/MB
- Bundles: 10MB-500MB
- Counts at GTP level — some overhead NOT counted
- Small packets have disproportionate overhead

## Optimization
1. TCP over UDP — fewer retransmissions
2. Keep connections alive
3. Send off-peak
4. Private APN if available
DOC

    # Make executable
    chmod +x "$CONFIG_DIR"/*.sh "$SCRIPT_DIR"/*.sh "$REPO_DIR/systemd"/*.sh

    echo "[+] Installed to $REPO_DIR"
    echo "[*] Edit IOT_SERVER in config/firewall-rules.sh"
    echo "[*] Edit IOT_ENDPOINT in scripts/background-sync.sh"
    echo "[*] Run 'bash iot-shaper.sh apply' (as root) to activate"
}

# ============================================================================
# APPLY - Run all root-level tweaks
# ============================================================================
apply_tweaks() {
    if ! su -c "id" >/dev/null 2>&1; then
        echo "[!] Root required. Phone must be rooted."
        exit 1
    fi
    echo "[*] Applying all tweaks..."
    su -c "bash $CONFIG_DIR/apn-config.sh"
    su -c "bash $CONFIG_DIR/network-tweaks.sh"
    su -c "bash $CONFIG_DIR/firewall-rules.sh"
    echo "[+] All tweaks applied."
}

# ============================================================================
# MONITOR - Show data usage
# ============================================================================
show_monitor() {
    bash "$SCRIPT_DIR/data-monitor.sh"
}

# ============================================================================
# TTL - Change TTL mode
# ============================================================================
set_ttl() {
    bash "$SCRIPT_DIR/ttl-spoof.sh" "$1"
}

# ============================================================================
# QUEUE / FLUSH - Background sync
# ============================================================================
queue_payload() {
    bash "$SCRIPT_DIR/background-sync.sh" queue "$1"
}
flush_queue() {
    bash "$SCRIPT_DIR/background-sync.sh" flush
}

# ============================================================================
# COMPRESS - Compress payload
# ============================================================================
compress_payload() {
    bash "$SCRIPT_DIR/compress-payload.sh" "$1" "$2"
}

# ============================================================================
# MAIN DISPATCH
# ============================================================================
case "$1" in
    install) install_all ;;
    apply) apply_tweaks ;;
    monitor) show_monitor ;;
    ttl) set_ttl "$2" ;;
    queue) queue_payload "$2" ;;
    flush) flush_queue ;;
    compress) compress_payload "$2" "$3" ;;
    *)
        echo "IoT Data Shaper for EMnify"
        echo "Usage:"
        echo "  bash $0 install              # Extract all scripts"
        echo "  bash $0 apply                # Apply tweaks (root)"
        echo "  bash $0 monitor              # Show data usage"
        echo "  bash $0 ttl [64|65|1|random|reset]"
        echo "  bash $0 queue '<json>'       # Queue payload"
        echo "  bash $0 flush                # Send queued payloads"
        echo "  bash $0 compress '<json>' [gzip|brotli|lzma|minify]"
        ;;
esac
