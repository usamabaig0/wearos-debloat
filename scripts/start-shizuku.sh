#!/usr/bin/env bash
set -euo pipefail

echo "=== Shizuku Runner for Wear OS ==="

if ! command -v adb &> /dev/null; then
    echo "Error: adb command not found."
    exit 1
fi

echo "Starting Shizuku service on watch..."
adb shell 'p=$(pm path moe.shizuku.privileged.api | cut -d: -f2 | sed "s/base.apk//"); ${p}lib/arm/libshizuku.so'
echo "Shizuku process invoked. Check Shizuku status in the watch app."
