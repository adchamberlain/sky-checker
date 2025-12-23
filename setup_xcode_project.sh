#!/bin/bash

# SkyChecker Xcode Project Setup Helper
# Run this after installing Xcode to create the project

echo "🔭 SkyChecker Xcode Project Setup"
echo "================================"
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed."
    echo ""
    echo "Please install Xcode from the Mac App Store first:"
    echo "1. Open Mac App Store"
    echo "2. Search for 'Xcode'"
    echo "3. Click 'Get' / 'Install'"
    echo "4. Wait for download to complete (~12GB)"
    echo "5. Run this script again"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n1)
echo "✅ Found: $XCODE_VERSION"
echo ""

# Accept Xcode license if needed
echo "Checking Xcode license..."
sudo xcodebuild -license accept 2>/dev/null || true

# Install iOS platform if needed
echo "Checking for iOS platform..."
xcodebuild -downloadPlatform iOS 2>/dev/null || true

echo ""
echo "================================"
echo "📋 Manual Steps Required"
echo "================================"
echo ""
echo "Unfortunately, Xcode projects must be created manually through the IDE."
echo "Please follow these steps:"
echo ""
echo "1. Open Xcode"
echo "   Command: open -a Xcode"
echo ""
echo "2. Create New Project (File → New → Project or ⌘⇧N)"
echo ""
echo "3. Select: iOS → App → Next"
echo ""
echo "4. Configure the project:"
echo "   • Product Name: SkyChecker"
echo "   • Organization Identifier: com.yourname"
echo "   • Interface: SwiftUI"
echo "   • Language: Swift"
echo "   • Storage: None"
echo "   • Uncheck 'Include Tests'"
echo ""
echo "5. Save to this directory:"
echo "   $(pwd)"
echo ""
echo "6. After project is created:"
echo "   a. Delete the auto-generated ContentView.swift and SkyCheckerApp.swift"
echo "   b. Right-click 'SkyChecker' folder → Add Files to 'SkyChecker'..."
echo "   c. Add these folders from $(pwd)/SkyChecker/:"
echo "      - Models"
echo "      - Services"
echo "      - ViewModels"
echo "      - Views"
echo "      - Resources"
echo "   d. Also add SkyCheckerApp.swift"
echo ""
echo "7. In Project Settings → SkyChecker target → General:"
echo "   • Set Minimum Deployments to iOS 16.0"
echo ""
echo "8. Press ⌘R to build and run!"
echo ""
echo "================================"
echo ""

# Offer to open Xcode
read -p "Would you like to open Xcode now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open -a Xcode
    echo "✅ Xcode opened!"
fi

echo ""
echo "Good luck with your stargazing! 🌟"

