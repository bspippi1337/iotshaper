#!/system/bin/sh
# Universal APN Configuration - Auto-detects carrier
# Supports: EMnify, Telenor, Telenor IoT/XCN, and generic fallback

echo "[*] Detecting carrier and configuring APN..."

# Get current operator info
CURRENT_MCCMNC=$(getprop gsm.sim.operator.numeric 2>/dev/null)
CURRENT_OPERATOR=$(getprop gsm.sim.operator.alpha 2>/dev/null)
CURRENT_ISO=$(getprop gsm.sim.operator.iso-country 2>/dev/null)

echo "[*] MCC+MNC: ${CURRENT_MCCMNC:-unknown}"
echo "[*] Operator: ${CURRENT_OPERATOR:-unknown}"
echo "[*] Country: ${CURRENT_ISO:-unknown}"

# Determine APN based on MCC+MNC or operator name
case "$CURRENT_MCCMNC" in
    90143|901-43)
        # EMnify
        APN_NAME="EMnify"; APN="em"; MCC="901"; MNC="43"
        ROAMING_REQUIRED=1
        echo "[+] Detected: EMnify IoT SIM"
        ;;
    23802|238-02|23820|238-20)
        # Telenor Denmark
        APN_NAME="Telenor IoT"; APN="telenor.iot"; MCC="238"; MNC="02"
        ROAMING_REQUIRED=0
        echo "[+] Detected: Telenor Denmark"
        ;;
    24201|242-01|24202|242-02)
        # Telenor Norway
        APN_NAME="Telenor Norway"; APN="internet.telenor.co"; MCC="242"; MNC="01"
        ROAMING_REQUIRED=0
        echo "[+] Detected: Telenor Norway"
        ;;
    24008|240-08|24004|240-04)
        # Telenor Sweden
        APN_NAME="Telenor Sweden"; APN="lpwa1.iot.telenor.se"; MCC="240"; MNC="08"
        ROAMING_REQUIRED=0
        echo "[+] Detected: Telenor Sweden"
        ;;
    *)
        # Try to detect by operator name
        OP_LOWER=$(echo "$CURRENT_OPERATOR" | tr '[:upper:]' '[:lower:]')
        case "$OP_LOWER" in
            *telenor*)
                APN_NAME="Telenor"; APN="telenor.iot"
                ROAMING_REQUIRED=0
                echo "[+] Detected: Telenor (generic)"
                ;;
            *emnify*|*em*)
                APN_NAME="EMnify"; APN="em"
                ROAMING_REQUIRED=1
                echo "[+] Detected: EMnify"
                ;;
            *)
                # Generic fallback - try common IoT APNs
                echo "[!] Unknown carrier: $CURRENT_MCCMNC / $CURRENT_OPERATOR"
                echo "[*] Trying generic IoT APNs..."
                APN_NAME="Generic IoT"; APN="internet"
                ROAMING_REQUIRED=0
                ;;
        esac
        ;;
esac

# Set operator properties
setprop gsm.operator.numeric "${MCC:-000}${MNC:-00}"
setprop gsm.sim.operator.numeric "${MCC:-000}${MNC:-00}"
setprop gsm.apn.sim.operator.numeric "${MCC:-000}${MNC:-00}"

# APN database update
APN_DB="/data/data/com.android.providers.telephony/databases/telephony.db"
if [ -f "$APN_DB" ] && command -v sqlite3 >/dev/null; then
    sqlite3 "$APN_DB" "INSERT OR REPLACE INTO carriers (name,numeric,mcc,mnc,apn,type,current,protocol,roaming_protocol,carrier_enabled,bearer) VALUES ('${APN_NAME}','${MCC}${MNC}','${MCC}','${MNC}','${APN}','default,supl,dun',1,'IPV4V6','IPV4V6',1,0);" 2>/dev/null
fi

# Roaming settings
if [ "$ROAMING_REQUIRED" = "1" ]; then
    echo "[*] Enabling data roaming (required for this SIM)..."
    settings put global data_roaming1 1 2>/dev/null
    settings put global data_roaming2 1 2>/dev/null
    setprop ro.com.android.dataroaming true 2>/dev/null || true

    # Fallback: modify settings.db directly
    SETTINGS_DB="/data/data/com.android.providers.settings/databases/settings.db"
    if [ -f "$SETTINGS_DB" ] && command -v sqlite3 >/dev/null; then
        sqlite3 "$SETTINGS_DB" "INSERT OR REPLACE INTO global (name,value) VALUES ('data_roaming1','1');" 2>/dev/null
        sqlite3 "$SETTINGS_DB" "INSERT OR REPLACE INTO global (name,value) VALUES ('data_roaming2','1');" 2>/dev/null
    fi
fi

settings put global roaming_indication_needed 0 2>/dev/null

# Restart radio
echo "[*] Restarting radio..."
svc data disable 2>/dev/null || service call phone 27 2>/dev/null
sleep 2
svc data enable 2>/dev/null || service call phone 26 2>/dev/null

sleep 3

# Verify
FINAL_OP=$(getprop gsm.apn.sim.operator.numeric 2>/dev/null)
FINAL_ROAM=$(settings get global data_roaming1 2>/dev/null || echo "unknown")
echo "[+] Operator: ${FINAL_OP:-$CURRENT_MCCMNC}"
echo "[+] APN: $APN"
echo "[+] Roaming: $FINAL_ROAM"
echo "[+] Status: $(if dumpsys telephony.registry | grep -q 'mDataConnectionState=2'; then echo 'CONNECTED'; else echo 'CONNECTING...'; fi)"
