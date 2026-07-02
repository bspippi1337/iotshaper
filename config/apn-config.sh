#!/system/bin/sh
# EMnify APN Configuration with Roaming
# Run as root

APN_NAME="EMnify"
APN="em"                    # EMnify standard APN
MCC="901"                   # EMnify MCC (shared network)
MNC="43"                    # EMnify MNC
AUTH_TYPE="0"               # None (EMnify uses IMEI auth)

echo "[*] Configuring EMnify APN..."

# Android APN database path
APN_DB="/data/data/com.android.providers.telephony/databases/telephony.db"

# Insert or update APN (requires SQLite3 on device or via magisk module)
# Alternative: use content provider or setprop

# Method 1: setprop for immediate effect (may not persist reboot)
setprop gsm.operator.numeric "$MCC$MNC"
setprop gsm.sim.operator.numeric "$MCC$MNC"
setprop gsm.apn.sim.operator.numeric "$MCC$MNC"

# Method 2: Telephony provider (more persistent)
# Requires sqlite3 binary or content command
if command -v sqlite3 >/dev/null; then
    sqlite3 "$APN_DB" <<EOF
INSERT OR REPLACE INTO carriers (
    name, numeric, mcc, mnc, apn, 
    type, current, protocol, roaming_protocol,
    carrier_enabled, bearer
) VALUES (
    '$APN_NAME', '$MCC$MNC', '$MCC', '$MNC', '$APN',
    'default,supl,dun', 1, 'IPV4V6', 'IPV4V6',
    1, 0
);
EOF
fi

# Force roaming enable (critical for EMnify global SIM)
echo "[*] Enabling data roaming..."
settings put global data_roaming1 1
settings put global data_roaming2 1
setprop ro.com.android.dataroaming true

# Disable roaming notification spam
settings put global roaming_indication_needed 0

# Restart radio to apply
echo "[*] Restarting radio interface..."
svc data disable
sleep 2
svc data enable

# Verify
sleep 3
CURRENT_APN=$(getprop gsm.apn.sim.operator.numeric)
echo "[+] Current operator: $CURRENT_APN"
echo "[+] Data roaming: $(settings get global data_roaming1)"