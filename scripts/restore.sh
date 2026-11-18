#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/../packages"

echo "=== Wear OS Restore Utility ==="

if ! command -v adb &> /dev/null; then
    echo "Error: adb command not found. Install Android platform-tools first."
    exit 1
fi

DEVICE_COUNT=$(adb devices | grep -v "List" | grep -c "device$" || true)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "No connected ADB devices detected."
    echo "Connect your watch first using: adb connect <WATCH_IP>:<PORT>"
    exit 1
fi

restore_pkg() {
    local pkg="$1"
    echo -n "  Restoring $pkg ... "
    if adb shell pm install-existing "$pkg" > /dev/null 2>&1; then
        adb shell pm enable "$pkg" > /dev/null 2>&1 || true
        echo "Restored"
    else
        echo "Not found or already active"
    fi
}

restore_file() {
    local file="$1"
    [ ! -f "$file" ] && return
    while IFS= read -r pkg || [ -n "$pkg" ]; do
        pkg=$(echo "$pkg" | tr -d '\r' | xargs)
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
        restore_pkg "$pkg"
    done < "$file"
}

if [ "$#" -gt 0 ]; then
    for pkg in "$@"; do
        restore_pkg "$pkg"
    done
    exit 0
fi

echo "Options:"
echo "1) Restore universal packages (Google Assistant, TalkBack, Retail loop)"
echo "2) Restore Samsung telemetry and factory stubs"
echo "3) Restore Bixby voice services"
echo "4) Restore everything from all package lists"
echo "5) Restore a specific package by name"
read -r -p "Select option [1-5]: " CHOICE

case "$CHOICE" in
    1)
        restore_file "${PACKAGE_DIR}/universal.txt"
        ;;
    2)
        restore_file "${PACKAGE_DIR}/samsung-telemetry.txt"
        restore_file "${PACKAGE_DIR}/samsung-factory.txt"
        ;;
    3)
        restore_file "${PACKAGE_DIR}/samsung-bixby.txt"
        ;;
    4)
        for f in "${PACKAGE_DIR}"/*.txt; do
            echo "Processing $(basename "$f")..."
            restore_file "$f"
        done
        ;;
    5)
        read -r -p "Enter package name (e.g. com.samsung.android.bixby.agent): " SINGLE_PKG
        if [ -n "$SINGLE_PKG" ]; then
            restore_pkg "$SINGLE_PKG"
        fi
        ;;
    *)
        echo "Invalid selection."
        exit 1
        ;;
esac

echo ""
echo "Restore operation finished."
