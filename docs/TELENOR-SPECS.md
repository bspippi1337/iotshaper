# Telenor IoT SIM

## APNs by Region

| Region | APN | MCC/MNC |
|--------|-----|---------|
| Denmark | `telenor.iot` | 238/02 |
| Norway | `internet.telenor.co` | 242/01 |
| Sweden | `lpwa1.iot.telenor.se` | 240/08 |
| Global/Generic | `telenor.iot` | varies |

## Features
- LTE-M, NB-IoT, 2G, 4G
- PSM (Power Saving Mode)
- eDRX (extended DRX)
- CGNAT (carrier-grade NAT)

## Notes
- Standard PIN: 1234 (usually disabled)
- PIN2: 0000
- Data overhead includes IP+UDP headers (28 bytes min)
- Control plane traffic (attach/detach) not rated
