# wearos-debloat

A clean toolkit and package reference to turn off background bloat, diagnostic trackers, and factory test stubs on Wear OS smartwatches over ADB.

Works without root. All removals use standard Android user-space commands (`pm disable-user --user 0` and `pm uninstall -k --user 0`). The system binaries stay untouched in the read-only system partition, so Samsung Knox stays 0x0 and any app can be restored immediately.

## Supported devices and generalization

This project is built to handle both universal Wear OS bloat and manufacturer-specific packages:

- **Universal Wear OS profile**: Applies to Google Pixel Watch, OnePlus Watch, Xiaomi Watch, Mobvoi TicWatch, and Samsung Galaxy Watch. Covers common bloat like retail demo attract loops, unused accessibility touch hooks, and generic assistant listeners.
- **Samsung One UI Watch profile**: Specifically targets Galaxy Watch 4, 5, 6, 7, and Ultra models. Covers Samsung diagnostic agents (`diagmonagent`, `dqagent`), Runestone analytics, Global Goals promotion stubs, Knox MDM clients, and assembly line hardware test tools.
- **Auto-detection**: The included scripts automatically query `ro.product.manufacturer` and `ro.product.model` to pick the right package lists for your specific watch.

---

## Method 1: Let an AI agent do it for you

If you use an AI coding assistant (such as Claude Code, Cursor, Codex, Gemini CLI, Hermes, or Aider), you do not need to run commands manually.

1. Open `AGENT_PROMPT.txt` in this repository.
2. Copy the prompt block.
3. Replace `<WATCH_IP>:<PORT>` with your watch's IP and current dynamic port.
4. Paste it into your agent's chat or terminal.

Your agent will connect to your watch, audit your installed packages, disable the matching bloatware, apply battery and Wi-Fi tweaks, start Shizuku if present, and output a before-and-after RAM report.

---

## Method 2: Manual / script quickstart

### Step 1: Connect to your watch over wireless ADB

1. On your watch, open **Settings -> Developer options -> Wireless debugging**.
2. Turn the toggle ON. Note down the IP address and the dynamic port shown on screen (e.g. `<WATCH_IP>:<PORT>`).
3. In your terminal on your computer, connect:
   ```bash
   adb connect <WATCH_IP>:<WATCH_PORT>
   ```
4. Look at your watch face and approve the ADB pairing prompt.

### Step 2: Run the debloat script

Clone the repo and run the debloat tool:

**Linux / macOS:**
```bash
git clone https://github.com/usamabaig0/wearos-debloat.git
cd wearos-debloat
chmod +x scripts/*.sh
./scripts/debloat.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/usamabaig0/wearos-debloat.git
cd wearos-debloat
.\scripts\debloat.ps1
```

The script auto-detects your watch model and guides you through what to remove.

---

## System settings tweaks

Run the settings tuning script to apply common battery and layout fixes:

```bash
./scripts/optimize-settings.sh
```

Or run the ADB commands manually:

```bash
# Stop the Wi-Fi chip from waking up to scan routers when Wi-Fi is toggled off
adb shell settings put global wifi_scan_always_enabled 0

# Enable 80% battery charging ceiling to reduce night-time heat degradation
adb shell settings put global protect_battery 1
adb shell settings put global battery_protection_threshold 80
adb shell settings put system protect_battery 1
adb shell settings put system battery_protection_threshold 80

# Speed up animations to 0.5x for faster UI transitions
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5

# (Optional) Tweak display density for extra screen room on larger watches
adb shell wm density 320

# Reset screen density back to factory default at any time
adb shell wm density reset
```

---

## Restoring packages

Because packages are disabled with the `-k` user-space flag, no files were permanently deleted. You can restore any package in seconds without a factory reset.

**Restore via script:**
```bash
./scripts/restore.sh
```

**Restore manually by package name:**
```bash
adb shell pm install-existing <package_name>
```

Examples:
```bash
# Restore Bixby
adb shell pm install-existing com.samsung.android.bixby.agent
adb shell pm install-existing com.samsung.android.bixby.wakeup

# Restore Google Assistant
adb shell pm install-existing com.google.android.wearable.assistant

# Restore TalkBack
adb shell pm install-existing com.google.android.marvin.talkback
```

---

## Running Shizuku on the watch

If you use tools like GeminiMan Wear OS Manager to freeze apps or run tweaks directly on the watch without a computer, you can launch Shizuku wirelessly:

1. Install Shizuku on the watch.
2. Run this ADB command while connected:
   ```bash
   adb shell 'p=$(pm path moe.shizuku.privileged.api | cut -d: -f2 | sed "s/base.apk//"); ${p}lib/arm/libshizuku.so'
   ```
3. Open Shizuku on the watch to verify the service is running.

---

## Repository layout

```
wearos-debloat/
├── AGENT_PROMPT.txt          # Ready-to-use prompt for AI coding agents
├── packages/
│   ├── universal.txt         # Bloat present across all Wear OS brands
│   ├── samsung-telemetry.txt # Samsung diagnostic loggers and trackers
│   ├── samsung-factory.txt   # Samsung manufacturing line test stubs
│   ├── samsung-bixby.txt     # Samsung Bixby voice listener
│   └── pixel-watch.txt       # Google Pixel Watch optional bloat
├── scripts/
│   ├── debloat.sh            # Auto-detecting Bash debloat script
│   ├── debloat.ps1           # Auto-detecting PowerShell debloat script
│   ├── restore.sh            # Interactive Bash restore script
│   ├── restore.ps1           # Interactive PowerShell restore script
│   ├── optimize-settings.sh  # Wi-Fi scanning, battery cap, animations, and DPI tweaks
│   ├── optimize-settings.ps1 # PowerShell settings optimizer
│   └── start-shizuku.sh      # Launcher for on-device Shizuku daemon
├── LICENSE
└── README.md
```

## Disclaimer
This repository is an independent community project. It is not affiliated with Samsung Electronics, Google, or any watch vendor. Always verify package names before removing them.
