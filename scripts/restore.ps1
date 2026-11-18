# PowerShell Wear OS Restore Utility
Write-Host "=== Wear OS Restore Utility ===" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pkgDir = Join-Path (Split-Path -Parent $scriptDir) "packages"

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Host "Error: adb not found in PATH." -ForegroundColor Red
    exit 1
}

function Restore-Pkg($pkg) {
    Write-Host "  Restoring: $pkg ... " -NoNewline
    adb shell pm install-existing $pkg 2>$null | Out-Null
    adb shell pm enable $pkg 2>$null | Out-Null
    Write-Host "Restored" -ForegroundColor Green
}

function Restore-List($filePath) {
    if (-not (Test-Path $filePath)) { return }
    Get-Content $filePath | ForEach-Object {
        $p = $_.Trim()
        if ($p -and -not $p.StartsWith("#")) { Restore-Pkg $p }
    }
}

Write-Host "Options:"
Write-Host "1) Restore universal packages (Google Assistant, TalkBack, Retail loop)"
Write-Host "2) Restore Samsung telemetry and factory stubs"
Write-Host "3) Restore Bixby voice services"
Write-Host "4) Restore everything from all package lists"
Write-Host "5) Restore a single package by name"
$choice = Read-Host "Select option [1-5]"

switch ($choice) {
    "1" { Restore-List (Join-Path $pkgDir "universal.txt") }
    "2" {
        Restore-List (Join-Path $pkgDir "samsung-telemetry.txt")
        Restore-List (Join-Path $pkgDir "samsung-factory.txt")
    }
    "3" { Restore-List (Join-Path $pkgDir "samsung-bixby.txt") }
    "4" {
        Get-ChildItem (Join-Path $pkgDir "*.txt") | ForEach-Object {
            Write-Host "Processing $($_.Name)..."
            Restore-List $_.FullName
        }
    }
    "5" {
        $single = Read-Host "Enter package name"
        if ($single) { Restore-Pkg $single.Trim() }
    }
    default {
        Write-Host "Invalid option." -ForegroundColor Red
    }
}

Write-Host "`nRestore complete." -ForegroundColor Cyan
