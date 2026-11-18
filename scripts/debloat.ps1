# PowerShell Wear OS Debloat Utility
Write-Host "=== Wear OS Debloat Utility ===" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pkgDir = Join-Path (Split-Path -Parent $scriptDir) "packages"

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Host "Error: adb not found in PATH. Install Android platform-tools first." -ForegroundColor Red
    exit 1
}

$deviceCount = (adb devices | Select-String "device$").Count
if ($deviceCount -eq 0) {
    Write-Host "No connected ADB devices detected." -ForegroundColor Yellow
    Write-Host "Connect your watch first: adb connect <WATCH_IP>:<PORT>"
    exit 1
}

$mfg = (adb shell getprop ro.product.manufacturer).Trim()
$model = (adb shell getprop ro.product.model).Trim()
$androidVer = (adb shell getprop ro.build.version.release).Trim()

Write-Host "Detected Device:"
Write-Host "  Manufacturer : $mfg"
Write-Host "  Model        : $model"
Write-Host "  Android / OS : $androidVer`n"

function Debloat-List($filePath, $category) {
    if (-not (Test-Path $filePath)) { return }
    Write-Host "--- $category ---" -ForegroundColor Yellow
    $installed = adb shell pm list packages
    Get-Content $filePath | ForEach-Object {
        $pkg = $_.Trim()
        if ($pkg -and -not $pkg.StartsWith("#")) {
            if ($installed -match "package:$pkg`$") {
                Write-Host "  Removing $pkg ... " -NoNewline
                adb shell pm disable-user --user 0 $pkg 2>$null | Out-Null
                adb shell pm uninstall -k --user 0 $pkg 2>$null | Out-Null
                Write-Host "Done" -ForegroundColor Green
            } else {
                Write-Host "  Skipped: $pkg (not installed)" -ForegroundColor DarkGray
            }
        }
    }
    Write-Host ""
}

# 1. Universal packages
Debloat-List (Join-Path $pkgDir "universal.txt") "Universal Wear OS Bloat"

# 2. Manufacturer-specific
if ($mfg -match "(?i)samsung") {
    Write-Host "Applying Samsung Galaxy Watch debloat profile..." -ForegroundColor Cyan
    Debloat-List (Join-Path $pkgDir "samsung-telemetry.txt") "Samsung Telemetry & Loggers"
    Debloat-List (Join-Path $pkgDir "samsung-factory.txt") "Samsung Factory Assembly Stubs"

    $removeBixby = Read-Host "Do you want to disable Samsung Bixby voice assistant? (y/N)"
    if ($removeBixby -match '^[yY]') {
        Debloat-List (Join-Path $pkgDir "samsung-bixby.txt") "Samsung Bixby"
    }
} elseif ($mfg -match "(?i)google") {
    Write-Host "Applying Google Pixel Watch debloat profile..." -ForegroundColor Cyan
    Debloat-List (Join-Path $pkgDir "pixel-watch.txt") "Pixel Watch Optional Services"
} else {
    Write-Host "Generic Wear OS device detected." -ForegroundColor Yellow
}

Write-Host "Debloat complete. Use scripts/restore.ps1 to restore any package." -ForegroundColor Cyan
