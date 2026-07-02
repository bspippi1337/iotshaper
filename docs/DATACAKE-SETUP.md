# Datacake Setup Guide

## 1. Sign Up
Go to https://datacake.co

## 2. Create Device
1. Click "Add Device"
2. Choose "API"
3. Note Device Serial
4. Copy API Token from Device Settings

## 3. Add Fields
| Field Name | Type | Identifier |
|------------|------|------------|
| Temperature | Float | `temp` |
| Battery | Integer | `bat` |
| Humidity | Float | `hum` |

## 4. Test
```bash
bash iot-shaper.sh queue '{"temp":23.5,"bat":87}'
bash iot-shaper.sh flush
```

## Free Tier
- 1 device free
- 10,000 API calls/month
- 30-day retention
