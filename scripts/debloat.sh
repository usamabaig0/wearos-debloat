#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/../packages"

echo "=== Wear OS Debloat Utility ==="

if ! command -v adb &> /dev/null; then
    echo "Error: adb command not found. Install Android platform-tools first."
    exit 1
fi

DEVICE_COUNT=$(adb devices | grep -v "List" | grep -c "device$" || true)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "No connected ADB devices detected."
    echo "Connect your watch first using:"
    echo "  adb connect <WATCH_IP>:<PORT>"
    exit 1
fi

# Detect device characteristics
MANUFACTURER=$(adb shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r' || echo "Unknown")
MODEL=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo "Unknown")
ANDROID_VER=$(adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r' || echo "Unknown")

echo "Detected Device:"
echo "  Manufacturer : ${MANUFACTURER}"
echo "  Model        : ${MODEL}"
echo "  Android / OS : ${ANDROID_VER}"
echo ""

debloat_file() {
    local file="$1"
    local category="$2"
    if [ ! -f "$file" ]; then
        return
    fi
    echo "--- Processing: $category ---"
    while IFS= read -r pkg || [ -n "$pkg" ]; do
        pkg=$(echo "$pkg" | tr -d '\r' | xargs)
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

        # Check if package is installed before attempting removal
        if adb shell pm list packages | grep -q "^package:${pkg}$"; then
            echo -n "  Removing $pkg ... "
            adb shell pm disable-user --user 0 "$pkg" > /dev/null 2>&1 || true
            adb shell pm uninstall -k --user 0 "$pkg" > /dev/null 2>&1 && echo "Done" || echo "Failed"
        else
            echo "  Skipped: $pkg (not installed)"
        fi
    done < "$file"
    echo ""
}

# 1. Universal packages safe for any Wear OS watch
debloat_file "${PACKAGE_DIR}/universal.txt" "Universal Wear OS Bloat"

# 2. Manufacturer-specific debloating
LOWER_MFG=$(echo "$MANUFACTURER" | tr '[:upper:]' '[:lower:]')

if [[ "$LOWER_MFG" == *"samsung"* ]]; then
    echo "Applying Samsung Galaxy Watch debloat profile..."
    debloat_file "${PACKAGE_DIR}/samsung-telemetry.txt" "Samsung Telemetry & Background Loggers"
    debloat_file "${PACKAGE_DIR}/samsung-factory.txt" "Samsung Factory Assembly Stubs"

    read -r -p "Do you want to disable Samsung Bixby voice assistant? [y/N]: " REMOVE_BIXBY
    if [[ "$REMOVE_BIXBY" =~ ^[Yy]$ ]]; then
        debloat_file "${PACKAGE_DIR}/samsung-bixby.txt" "Samsung Bixby"
    fi
elif [[ "$LOWER_MFG" == *"google"* ]]; then
    echo "Applying Google Pixel Watch debloat profile..."
    debloat_file "${PACKAGE_DIR}/pixel-watch.txt" "Pixel Watch Optional Services"
else
    echo "Generic Wear OS device detected."
    read -r -p "Do you want to check and run the Samsung package lists just in case? [y/N]: " CHECK_SAMSUNG
    if [[ "$CHECK_SAMSUNG" =~ ^[Yy]$ ]]; then
        debloat_file "${PACKAGE_DIR}/samsung-telemetry.txt" "Samsung Telemetry"
        debloat_file "${PACKAGE_DIR}/samsung-factory.txt" "Samsung Factory Stubs"
    fi
fi

echo "Debloat complete. Original APKs remain in system partition."
echo "Restore any package at any time using: ./scripts/restore.sh"
