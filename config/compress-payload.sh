#!/data/data/com.termux/files/usr/bin/bash
# Compression wrapper for IoT payloads
# Reduces data size by 60-90% for JSON/text data

PAYLOAD="$1"
METHOD="${2:-gzip}"  # gzip, brotli, or lzma

case "$METHOD" in
    gzip)
        # Standard gzip, widely supported
        echo "$PAYLOAD" | gzip -c -9 | base64 -w 0
        ;;
    brotli)
        # Best compression ratio, requires brotli binary
        if command -v brotli >/dev/null; then
            echo "$PAYLOAD" | brotli -c -q 11 | base64 -w 0
        else
            echo "[!] brotli not installed, falling back to gzip"
            echo "$PAYLOAD" | gzip -c -9 | base64 -w 0
        fi
        ;;
    lzma)
        # Extreme compression, slow
        echo "$PAYLOAD" | xz -c -9e | base64 -w 0
        ;;
    minify)
        # For JSON: strip whitespace first, then gzip
        echo "$PAYLOAD" | python3 -c "import sys,json; json.dump(json.load(sys.stdin), sys.stdout, separators=(',',':'))" 2>/dev/null | gzip -c -9 | base64 -w 0
        ;;
esac