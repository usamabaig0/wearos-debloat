#!/usr/bin/env bash
set -euo pipefail

echo "=== Shizuku Runner for Wear OS ==="

if ! command -v adb &> /dev/null; then
    echo "Error: adb command not found."
    exit 1
fi

echo "Starting Shizuku service on watch (supporting 32-bit and 64-bit Wear OS)..."
adb shell 'p=$(pm path moe.shizuku.privileged.api | head -n 1 | cut -d: -f2 | sed "s/base.apk//"); if [ -f "${p}lib/arm64/libshizuku.so" ]; then "${p}lib/arm64/libshizuku.so"; elif [ -f "${p}lib/arm/libshizuku.so" ]; then "${p}lib/arm/libshizuku.so"; else for f in "${p}"lib/*/libshizuku.so; do [ -f "$f" ] && "$f" && break; done; fi'
echo "Shizuku process invoked. Check Shizuku status in the watch app."
