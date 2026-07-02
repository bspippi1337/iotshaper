# EMnify IoT SIM Configuration

## APN Settings

| Parameter | Value |
|-----------|-------|
| APN Name | `em` |
| Username | (blank) |
| Password | (blank) |
| Auth Type | None |
| MCC | 901 |
| MNC | 43 |
| Protocol | IPv4v6 |

## Roaming Requirements

EMnify SIMs are **global roaming** by default.
- Must enable data roaming in Android settings
- No additional charges for roaming
- Connects to strongest available network

## Data Plans

- Pay-per-use: ~$0.10/MB
- Bundles: Available from 10MB to 500MB
- **Key insight**: EMnify counts data at the GTP level
  - Some overhead is NOT counted (GTP headers)
  - Small packets have disproportionate overhead

## Optimization for EMnify

1. **Use TCP over UDP** - More reliable, fewer retransmissions
2. **Keep connections alive** - Avoid repeated handshakes
3. **Send during off-peak** - Network less congested, fewer retries
4. **Use private APN** - If available, bypasses public internet counting