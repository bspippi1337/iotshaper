# IoT Data Shaper for EMnify

Minimize countable mobile data usage for IoT projects on Android/Termux.

## Target: &lt;50MB/month

## Quick Start

```bash
# 1. Clone/create repo in Termux
mkdir -p ~/iot-data-shaper && cd ~/iot-data-shaper

# 2. Create all files from this repo
# (Copy-paste scripts above)

# 3. Run setup
bash setup.sh

# 4. Reboot or restart radio
su -c "svc data disable && sleep 2 && svc data enable"