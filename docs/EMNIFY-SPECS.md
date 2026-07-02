# EMnify IoT SIM

## APN
| Param | Value |
|-------|-------|
| APN | `em` |
| User/Pass | (blank) |
| Auth | None (IMEI-based) |
| MCC/MNC | 901/43 |
| Protocol | IPv4v6 |

## Roaming
Required. Global SIM. No roaming charges.

## Data Plans
- Pay-per-use: ~$0.10/MB
- Bundles: 10MB-500MB
- Counts at GTP level — some overhead NOT counted
- Small packets have disproportionate overhead

## Optimization
1. TCP over UDP — fewer retransmissions
2. Keep connections alive
3. Send off-peak
4. Private APN if available
