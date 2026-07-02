#!/system/bin/sh
# Universal APN Configuration - Auto-detects carrier
# Supports: EMnify, Telenor (all regions), generic fallback

echo "[*] Detecting carrier..."

CURRENT_MCCMNC=$(getprop gsm.sim.operator.numeric 2>/dev/null)
CURRENT_OPERATOR=$(getprop gsm.sim.operator.alpha 2>/dev/null)

echo "[*] MCC+MNC: ${CURRENT_MCCMNC:-unknown}"
echo "[*] Operator: ${CURRENT_OPERATOR:-unknown}"

case "$CURRENT_MCCMNC" in
    90143|901-43)
        APN_NAME="EMnify"; APN="em"; MCC="901"; MNC="43"; ROAMING=1
        echo "[+] EMnify detected"
        ;;
    23802|238-02|23820|238-20)
        APN_NAME="Telenor DK"; APN="telenor.iot"; MCC="238"; MNC="02"; ROAMING=0
        echo "[+] Telenor Denmark detected"
        ;;
    24201|242-01|24202|242-02)
        APN_NAME="Telenor NO"; APN="internet.telenor.co"; MCC="242"; MNC="01"; ROAMING=0
        echo "[+] Telenor Norway detected"
        ;;
    24008|240-08|24004|240-04)
        APN_NAME="Telenor SE"; APN="lpwa1.iot.telenor.se"; MCC="240"; MNC="08"; ROAMING=0
        echo "[+] Telenor Sweden detected"
        ;;
    *)
        OP_LOWER=$(echo "$CURRENT_OPERATOR" | tr '[:upper:]' '[:lower:]')
        case "$OP_LOWER" in
            *telenor*)
                APN_NAME="Telenor"; APN="telenor.iot"; ROAMING=0
                echo "[+] Telenor (generic) detected"
                ;;
            *emnify*)
                APN_NAME="EMnify"; APN="em"; ROAMING=1
                echo "[+] EMnify detected"
                ;;
            *)
                APN_NAME="Generic"; APN="internet"; ROAMING=0
                echo "[!] Unknown carrier, using generic APN"
                ;;
        esac
        ;;
esac

# Set properties
setprop gsm.operator.numeric "${MCC:-000}${MNC:-00}"
setprop gsm.sim.operator.numeric "${MCC:-000}${MNC:-00}"
setprop gsm.apn.sim.operator.numeric "${MCC:-000}${MNC:-00}"

# APN database
APN_DB="/data/data/com.android.providers.telephony/databases/telephony.db"
if [ -f "$APN_DB" ] && command -v sqlite3 >/dev/null; then
    sqlite3 "$APN_DB" "INSERT OR REPLACE INTO carriers (name,numeric,mcc,mnc,apn,type,current,protocol,roaming_protocol,carrier_enabled,bearer) VALUES ('${APN_NAME}','${MCC}${MNC}','${MCC}','${MNC}','${APN}','default,supl,dun',1,'IPV4V6','IPV4V6',1,0);" 2>/dev/null
fi

# Roaming
if [ "$ROAMING" = "1" ]; then
    settings put global data_roaming1 1 2>/dev/null
    settings put global data_roaming2 1 2>/dev/null
    setprop ro.com.android.dataroaming true 2>/dev/null || true
    SETTINGS_DB="/data/data/com.android.providers.settings/databases/settings.db"
    if [ -f "$SETTINGS_DB" ] && command -v sqlite3 >/dev/null; then
        sqlite3 "$SETTINGS_DB" "INSERT OR REPLACE INTO global (name,value) VALUES ('data_roaming1','1');" 2>/dev/null
        sqlite3 "$SETTINGS_DB" "INSERT OR REPLACE INTO global (name,value) VALUES ('data_roaming2','1');" 2>/dev/null
    fi
fi

settings put global roaming_indication_needed 0 2>/dev/null

# Restart radio
svc data disable 2>/dev/null || service call phone 27 2>/dev/null
sleep 2
svc data enable 2>/dev/null || service call phone 26 2>/dev/null

sleep 3

FINAL_OP=$(getprop gsm.apn.sim.operator.numeric 2>/dev/null)
FINAL_ROAM=$(settings get global data_roaming1 2>/dev/null || echo "unknown")
echo "[+] Operator: ${FINAL_OP:-$CURRENT_MCCMNC}"
echo "[+] APN: $APN"
echo "[+] Roaming: $FINAL_ROAM"

# Check connection state
if dumpsys telephony.registry | grep -q 'mDataConnectionState=2' 2>/dev/null; then
    echo "[+] Data: CONNECTED"
else
    echo "[*] Data: CONNECTING..."
fi
