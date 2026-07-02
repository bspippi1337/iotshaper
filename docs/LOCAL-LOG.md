# Local Log Storage

## How It Works

Instead of sending to a cloud service, data is stored locally on the device:

1. `queue '<json>'` — Saves payload to `queue/` as JSON with timestamp
2. `flush` — Appends all queued payloads to `logs/payloads.jsonl`
3. Data persists across reboots

## File Locations

| File | Purpose |
|------|---------|
| `queue/*.json` | Pending payloads (cleared on flush) |
| `logs/payloads.jsonl` | Persistent log (JSON Lines format) |
| `logs/usage.log` | Data usage tracking |
| `logs/monitor.log` | Cron monitor output |

## Reading Logs

```bash
# View all payloads
cat ~/iot-data-shaper/logs/payloads.jsonl

# View last 10 payloads
tail -n 10 ~/iot-data-shaper/logs/payloads.jsonl

# Parse with jq (install: pkg install jq)
jq -r '.data.temp' ~/iot-data-shaper/logs/payloads.jsonl

# Export to CSV
jq -r '[.timestamp, .data.temp, .data.bat] | @csv' ~/iot-data-shaper/logs/payloads.jsonl
```

## JSON Lines Format

Each line is a valid JSON object:
```json
{"timestamp":1699999999,"data":{"temp":23.5,"bat":87}}
{"timestamp":1700000000,"data":{"temp":23.6,"bat":86}}
```

## Backup

```bash
# Copy logs to external storage
cp ~/iot-data-shaper/logs/payloads.jsonl /sdcard/iot-backup/

# Or sync via adb
adb pull /data/data/com.termux/files/home/iot-data-shaper/logs/payloads.jsonl
```
