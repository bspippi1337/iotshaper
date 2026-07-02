# Datacake Setup Guide

## 1. Sign Up
Go to https://datacake.co and create a free account.

## 2. Create a Device
1. Click "Add Device"
2. Choose "API" as integration type
3. Note your **Device Serial**
4. Go to Device Settings → API → copy **API Token**

## 3. Configure Fields
In the Datacake dashboard, add fields matching your JSON keys:

| Field Name | Type | Identifier | Unit |
|------------|------|------------|------|
| Temperature | Float | `temp` | °C |
| Battery | Integer | `bat` | % |
| Humidity | Float | `hum` | % |

## 4. Configure This Tool
Run `bash iot-shaper.sh install` and enter your credentials when prompted.

## 5. Test

```bash
bash iot-shaper.sh queue '{"temp":23.5,"bat":87}'
bash iot-shaper.sh flush
```

## 6. JSON Format

Datacake expects flat JSON with field identifiers as keys:

```json
{"temp": 23.5, "bat": 87, "hum": 45.2}
```

## Free Tier Limits
- 1 device free
- 10,000 API calls/month
- 30-day data retention
