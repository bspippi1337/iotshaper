#!/system/bin/sh
# EMnify APN Configuration with Roaming
# Run as root

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
