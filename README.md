# SkyChecker

A native iOS app that shows you what celestial objects are visible tonight from your location. Track planets, deep sky objects, the ISS, meteor showers, and more — with live weather conditions.

Built with SwiftUI and featuring a retro terminal aesthetic with ASCII art visualizations.

## 📱 Available on the App Store

**SkyChecker is available for free on the iOS App Store!**

[![Download on the App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/us/app/skychecker/id6757621845)

*No Xcode required — just download and go.*

**Website:** [skychecker.app](https://skychecker.app)

---

## Features

### Celestial Objects
- **Moon** with phase, illumination percentage, and ASCII art
- **All planets** from Mercury through Neptune
- **Deep sky objects** — Andromeda Galaxy (M31), Orion Nebula (M42), Pleiades (M45), and more
- **ISS passes** — know when the space station flies over
- **Meteor shower alerts** — notifications for upcoming showers with peak times and rates

### Weather Integration
- **Live conditions** from Open-Meteo API
- **Cloud cover** breakdown (low/mid/high layers)
- **Observation rating** (1-5 stars) based on clouds, visibility, humidity, and wind
- **Tips** for optimal viewing based on current conditions

### Planning Tools
- **Difficulty ratings** — know what equipment you need (Naked Eye, Binoculars, Small Telescope)
- **Rise, set, and peak times** with compass directions
- **Date picker** for planning future observing sessions
- **Share** tonight's sky with friends

### Other Features
- Automatic GPS location or manual coordinate entry
- Accurate sunset/sunrise calculations
- Smart caching for fast app launch
- Terminal-style UI with ASCII art
- Free. No ads. No tracking.

## Requirements

- iPhone running iOS 16.0 or later
- Internet connection for API calls (NASA Horizons, Open-Meteo)

---

## Installation

### Option 1: App Store (Recommended)
Download directly from the [App Store](https://apps.apple.com/us/app/skychecker/id6757621845).

### Option 2: Build from Source

**Requirements:**
- Mac with Xcode 15+ installed
- Free Apple ID (for personal device installation)

**Steps:**

1. **Clone the repository**
   ```bash
   git clone https://github.com/adchamberlain/sky-checker.git
   ```

2. **Open in Xcode**
   ```bash
   cd sky-checker/SkyChecker/SkyChecker
   open SkyChecker.xcodeproj
   ```

3. **Configure code signing**
   - Select the SkyChecker target
   - Go to Signing & Capabilities
   - Check "Automatically manage signing"
   - Select your Personal Team

4. **Build and run**
   - Connect your iPhone via USB
   - Select your device as the target
   - Press ⌘R to build and run

> **Note**: With a free Apple ID, apps expire after 7 days and must be reinstalled. A paid Apple Developer account ($99/year) removes this limitation.

---

## How It Works

SkyChecker combines data from multiple sources:

- **NASA JPL Horizons System** — Real-time ephemeris data for planets and moon (the same data NASA uses for spacecraft navigation)
- **Open-Meteo** — Weather forecasts including cloud cover, visibility, and humidity
- **Local calculations** — Deep sky object positions computed using astronomical algorithms

The app calculates:
- **Visibility** — Whether an object is above the horizon during nighttime hours
- **Rise/Set Times** — When objects rise and set, with compass directions
- **Transit Times** — When objects reach their highest point in the sky
- **Moon Phase** — Current lunar illumination and phase name
- **Observation Conditions** — Rating based on weather factors

---

## Troubleshooting

### "Untrusted Developer" error
Go to Settings → General → VPN & Device Management → Trust your developer certificate.

### App expires after 7 days
This is normal with a free Apple ID. Reconnect your iPhone and press ⌘R in Xcode to reinstall.

### Weather not loading
Weather requires an internet connection. Pull to refresh to retry.

---

## Credits

**Author**: Andrew Chamberlain, Ph.D. ([andrewchamberlain.com](https://andrewchamberlain.com))

**Data Sources**:
- [NASA JPL Horizons System](https://ssd.jpl.nasa.gov/horizons/)
- [Open-Meteo Weather API](https://open-meteo.com/)

**License**: MIT
