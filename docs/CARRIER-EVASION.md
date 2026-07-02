# Carrier Data Counting Evasion Techniques

## How Mobile Carriers Count Data

1. **Deep Packet Inspection (DPI)**
   - Carriers inspect packet headers, ports, and protocols
   - TTL values reveal device type (OS fingerprinting)
   - Standard TTLs: Android/Linux=64, Windows=128, iOS=64

2. **APN-Based Categorization**
   - Different APNs for "consumer" vs "machine" data
   - EMnify uses IMEI-based authentication (no user credentials)
   - Some carriers exempt "machine-to-machine" traffic

3. **Protocol Analysis**
   - HTTP/HTTPS on port 443/80 = user data
   - Custom ports, VPN tunnels = often treated differently
   - ICMP and UDP may be counted differently than TCP

## TTL Manipulation Strategy

| TTL Value | Appears As | Carrier Interpretation |
|-----------|-----------|----------------------|
| 64 | Standard Android | Normal user data |
| 65 | Tethered/hopped | Often "tethered" category |
| 128 | Windows device | Different OS profile |
| 1 | Local network | May be dropped or exempt |
| Random | Inconsistent | Evasion detection risk |

## MTU Optimization

Standard MTU: 1500 bytes
- IP header: 20 bytes
- TCP header: 20 bytes
- Options: 0-40 bytes
- Payload: ~1440 bytes

Mobile networks add:
- GTP tunneling: 8 bytes
- IPsec/encryption: 20-40 bytes
- Result: Fragmentation at 1500

**Optimal IoT MTU: 1280**
- Minimum IPv6 requirement (guaranteed end-to-end)
- No fragmentation in most networks
- Slightly more overhead per byte, but less retransmission

## Data Shaping Rules

1. **Block telemetry** - Android/Google background data
2. **Rate limit** - Prevent burst counting
3. **Compress payloads** - 60-90% reduction
4. **Batch uploads** - Fewer connections = less overhead
5. **Use UDP where possible** - Some carriers count UDP differently

## EMnify Specifics

- APN: `em` (no username/password)
- Authentication: IMEI-based
- Roaming: Required (global SIM)
- IP assignment: NAT behind carrier-grade NAT
- Data counting: Typically session-based, not packet-based