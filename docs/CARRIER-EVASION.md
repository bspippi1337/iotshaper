# Carrier Data Counting Evasion

## How Carriers Count Data
1. DPI — inspect headers, ports, protocols
2. TTL fingerprinting — Android=64, Windows=128, iOS=64
3. APN categorization — consumer vs machine data
4. Protocol analysis — HTTP/443 = user data

## TTL Strategy
| TTL | Appears As | Interpretation |
|-----|-----------|----------------|
| 64 | Standard Android | Normal user data |
| 65 | Tethered/hopped | Often exempt |
| 128 | Windows | Different profile |
| 1 | Local | May be dropped |

## MTU Optimization
Standard MTU=1500. Mobile adds GTP(8b)+IPsec(20-40b) = fragmentation.
Optimal IoT MTU=1280 — no fragmentation, less retransmission.

## Rules
1. Block telemetry
2. Rate limit bursts
3. Compress payloads (60-90%)
4. Batch uploads
5. UDP may count differently than TCP
