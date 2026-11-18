#!/usr/bin/env bash
set -euo pipefail

echo "=== Wear OS Settings Optimizer ==="

if ! command -v adb &> /dev/null; then
    echo "Error: adb command not found."
    exit 1
fi

DEVICE_COUNT=$(adb devices | grep -v "List" | grep -c "device$" || true)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "No connected ADB devices detected."
    echo "Connect your watch first using: adb connect <WATCH_IP>:<PORT>"
    exit 1
fi

echo "1. Disabling background Wi-Fi scanning (wifi_scan_always_enabled = 0)..."
adb shell settings put global wifi_scan_always_enabled 0
echo "   Current value: $(adb shell settings get global wifi_scan_always_enabled)"

echo "2. Applying battery protection (protect_battery = 1, threshold = 80%)..."
adb shell settings put global protect_battery 1 > /dev/null 2>&1 || true
adb shell settings put global battery_protection_threshold 80 > /dev/null 2>&1 || true
adb shell settings put system protect_battery 1 > /dev/null 2>&1 || true
adb shell settings put system battery_protection_threshold 80 > /dev/null 2>&1 || true
echo "   Battery protection enabled at 80%."

echo "3. Setting UI animation scales to 0.5x for faster UI navigation..."
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
echo "   Animation scales updated to 0.5x."

echo ""
CURRENT_DENSITY=$(adb shell wm density | tr -d '\r')
echo "Current screen density: ${CURRENT_DENSITY}"
read -r -p "Do you want to adjust DPI to 320 (compact layout) or reset? [320/reset/skip]: " DPI_CHOICE
case "$DPI_CHOICE" in
    320)
        adb shell wm density 320
        echo "   DPI updated to 320."
        ;;
    reset)
        adb shell wm density reset
        echo "   DPI reset to default."
        ;;
    *)
        echo "   DPI unchanged."
        ;;
esac

echo ""
echo "Settings optimization completed."
