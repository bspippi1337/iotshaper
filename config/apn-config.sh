#!/system/bin/sh
# Universal APN - handles SELinux restrictions gracefully

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

# APN database (silent fail if not available)
APN_DB="/data/data/com.android.providers.telephony/databases/telephony.db"
if [ -f "$APN_DB" ] && command -v sqlite3 >/dev/null; then
    sqlite3 "$APN_DB" "INSERT OR REPLACE INTO carriers (name,numeric,mcc,mnc,apn,type,current,protocol,roaming_protocol,carrier_enabled,bearer) VALUES ('${APN_NAME}','${MCC}${MNC}','${MCC}','${MNC}','${APN}','default,supl,dun',1,'IPV4V6','IPV4V6',1,0);" 2>/dev/null
fi

# Roaming - try settings, fallback to setprop
if [ "$ROAMING" = "1" ]; then
    settings put global data_roaming1 1 2>/dev/null || true
    settings put global data_roaming2 1 2>/dev/null || true
    setprop ro.com.android.dataroaming true 2>/dev/null || true
fi

settings put global roaming_indication_needed 0 2>/dev/null || true

# Restart radio - try multiple methods
(svc data disable >/dev/null 2>&1 || service call phone 27 >/dev/null 2>&1) && sleep 2 && (svc data enable >/dev/null 2>&1 || service call phone 26 >/dev/null 2>&1) || true

sleep 3

FINAL_OP=$(getprop gsm.apn.sim.operator.numeric 2>/dev/null)
echo "[+] Operator: ${FINAL_OP:-$CURRENT_MCCMNC}"
echo "[+] APN: $APN"

# Check connection
dumpsys telephony.registry 2>/dev/null | grep -q 'mDataConnectionState=2' && echo "[+] Data: CONNECTED" || echo "[*] Data: CONNECTING..."
