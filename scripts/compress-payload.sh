#!/data/data/com.termux/files/usr/bin/bash
# Compression wrapper for IoT payloads

PAYLOAD="$1"; METHOD="${2:-gzip}"

case "$METHOD" in
    gzip) echo "$PAYLOAD" | gzip -c -9 | base64 -w 0 ;;
    brotli) command -v brotli >/dev/null && echo "$PAYLOAD" | brotli -c -q 11 | base64 -w 0 || { echo "[!] No brotli, using gzip"; echo "$PAYLOAD" | gzip -c -9 | base64 -w 0; } ;;
    lzma) echo "$PAYLOAD" | xz -c -9e | base64 -w 0 ;;
    minify) echo "$PAYLOAD" | python3 -c "import sys,json; json.dump(json.load(sys.stdin), sys.stdout, separators=(',',':'))" 2>/dev/null | gzip -c -9 | base64 -w 0 ;;
esac
