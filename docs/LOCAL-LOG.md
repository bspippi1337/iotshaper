# Local Log Storage

## How It Works

Data is stored locally on the device:

1. `queue '<json>'` — Saves to `queue/*.json`
2. `flush` — Appends to `logs/payloads.jsonl`

## Files

| File | Purpose |
|------|---------|
| `queue/*.json` | Pending payloads |
| `logs/payloads.jsonl` | Persistent log |
| `logs/usage.log` | Data usage |

## Reading Logs

```bash
cat ~/iot-data-shaper/logs/payloads.jsonl
tail -n 10 ~/iot-data-shaper/logs/payloads.jsonl
```
