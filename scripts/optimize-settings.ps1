# PowerShell Wear OS Settings Optimizer
Write-Host "=== Wear OS Settings Optimizer ===" -ForegroundColor Cyan

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Host "Error: adb not found in PATH." -ForegroundColor Red
    exit 1
}

$deviceCount = (adb devices | Select-String "device$").Count
if ($deviceCount -eq 0) {
    Write-Host "No connected ADB devices detected." -ForegroundColor Yellow
    Write-Host "Connect your watch first: adb connect <WATCH_IP>:<PORT>"
    exit 1
}

Write-Host "1. Disabling background Wi-Fi scanning..."
adb shell settings put global wifi_scan_always_enabled 0
Write-Host "   Done." -ForegroundColor Green

Write-Host "2. Applying battery protection (80% ceiling)..."
adb shell settings put global protect_battery 1 2>$null | Out-Null
adb shell settings put global battery_protection_threshold 80 2>$null | Out-Null
adb shell settings put system protect_battery 1 2>$null | Out-Null
adb shell settings put system battery_protection_threshold 80 2>$null | Out-Null
Write-Host "   Done." -ForegroundColor Green

Write-Host "3. Setting animation speeds to 0.5x..."
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
Write-Host "   Window, transition, and animator scales set to 0.5x." -ForegroundColor Green

Write-Host ""
$currentDensity = (adb shell wm density).Trim()
Write-Host "Current screen density: $currentDensity"
$dpiChoice = Read-Host "Adjust DPI to 320 or reset to default? [320/reset/skip]"
switch ($dpiChoice) {
    "320" {
        adb shell wm density 320
        Write-Host "   DPI updated to 320." -ForegroundColor Green
    }
    "reset" {
        adb shell wm density reset
        Write-Host "   DPI reset to default." -ForegroundColor Green
    }
    default {
        Write-Host "   DPI unchanged."
    }
}

Write-Host "`nSettings optimization complete." -ForegroundColor Cyan
