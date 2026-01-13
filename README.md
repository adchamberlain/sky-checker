# SkyChecker

A native iOS app that shows you what celestial objects are visible tonight from your location, using NASA's Horizons Ephemeris API.

Built with SwiftUI and featuring a retro terminal aesthetic with ASCII art visualizations.

## 📱 Available on the App Store

**SkyChecker is available for free on the iOS App Store!**

[![Download on the App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/us/app/skychecker/id6757621845)

*No Xcode required — just download and go.*

**Website:** [skychecker.app](https://skychecker.app)

---

## Features

- Automatic GPS location or manual coordinate entry
- Accurate sunset/sunrise calculations
- Tonight's viewing list: Moon (with phase), planets (Mercury through Neptune)
- Rise, set, and peak times with compass directions
- Date picker for planning future observing sessions
- Offline caching
- Terminal-style UI with ASCII art for Moon phases

## Requirements

- iPhone running iOS 16.0 or later
- Mac with Xcode 15+ installed
- Free Apple ID (for personal device installation)
- Internet connection for NASA API calls

---

## Installation Guide

Follow these steps to download and install SkyChecker on your iPhone.

### Step 1: Download the Code

**Option A: Using Git (recommended)**
```bash
git clone https://github.com/adchamberlain/sky-checker.git
```

**Option B: Download ZIP**
1. Go to https://github.com/adchamberlain/sky-checker
2. Click the green **"Code"** button
3. Click **"Download ZIP"**
4. Unzip the downloaded file

### Step 2: Open in Xcode

1. Open **Finder** and navigate to the downloaded folder
2. Go to: `sky-checker/SkyChecker/SkyChecker/`
3. Double-click **`SkyChecker.xcodeproj`** to open it in Xcode

Or from Terminal:
```bash
cd sky-checker/SkyChecker/SkyChecker
open SkyChecker.xcodeproj
```

### Step 3: Configure Code Signing

This allows the app to run on your personal iPhone.

1. In Xcode, click on **"SkyChecker"** in the left sidebar (the blue project icon at the top)
2. Under **TARGETS**, select **"SkyChecker"**
3. Click the **"Signing & Capabilities"** tab
4. Check ✅ **"Automatically manage signing"**
5. Click the **Team** dropdown:
   - If you see your name, select it
   - If not, click **"Add an Account..."** and sign in with your Apple ID
6. Select **"Your Name (Personal Team)"**

> ⚠️ **Note**: With a free Apple ID, apps expire after 7 days and must be reinstalled. A paid Apple Developer account ($99/year) removes this limitation.

### Step 4: Connect Your iPhone

1. Connect your iPhone to your Mac with a USB cable
2. **On your iPhone**: When prompted "Trust This Computer?", tap **Trust** and enter your passcode
3. Wait a few seconds for Xcode to recognize your device

### Step 5: Select Your iPhone as the Target

1. At the top of Xcode, find the device selector (it may say "iPhone 15 Pro" or similar)
2. Click the dropdown
3. Under **"iOS Devices"**, select your connected iPhone

![Device selector location](https://developer.apple.com/assets/elements/icons/xcode-12/xcode-12-96x96_2x.png)

### Step 6: Build and Run

1. Press **⌘R** (Command + R) or click the **▶ Play** button
2. Xcode will build the app and install it on your iPhone
3. **First time only**: The build may take 1-2 minutes

### Step 7: Trust the Developer Certificate (First Time Only)

The first time you install, your iPhone won't run the app until you trust it:

1. On your iPhone, go to **Settings**
2. Tap **General**
3. Tap **VPN & Device Management**
4. Under "Developer App", tap your **Apple ID email**
5. Tap **"Trust [your email]"**
6. Tap **Trust** to confirm

### Step 8: Launch the App

1. Return to your iPhone home screen
2. Find the **SkyChecker** app icon
3. Tap to open!

The app will ask for location permission — tap **"Allow While Using App"** for the best experience.

---

## Troubleshooting

### "Untrusted Developer" error
See Step 7 above to trust the developer certificate.

### Play button is greyed out
- Make sure your iPhone is connected and selected as the target device
- Check that code signing is configured (Step 3)

### "Could not launch" error
- Unlock your iPhone screen
- Try unplugging and reconnecting your iPhone

### App expires after 7 days
This is normal with a free Apple ID. Just reconnect your iPhone and press ⌘R in Xcode to reinstall.

---

## How It Works

SkyChecker queries NASA's Jet Propulsion Laboratory (JPL) Horizons System to get real-time ephemeris data for celestial objects. It calculates:

- **Visibility**: Whether an object is above the horizon during nighttime hours
- **Rise/Set Times**: When objects rise and set, with compass directions
- **Transit Times**: When objects reach their highest point in the sky
- **Moon Phase**: Current lunar illumination and phase name

All calculations are based on your precise GPS location and local timezone.

---

## Credits

**Author**: Andrew Chamberlain, Ph.D. ([andrewchamberlain.com](https://andrewchamberlain.com))

**Data**: [NASA JPL Horizons System](https://ssd.jpl.nasa.gov/horizons/)

**License**: MIT
