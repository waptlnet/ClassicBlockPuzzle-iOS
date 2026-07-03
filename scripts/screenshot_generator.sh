#!/bin/bash
# App Store Screenshot Generator — ClassicBlockPuzzle
# Usage: Copy this to your Mac, run in project root
# Prerequisites: Xcode CLI, Xcode Simulator booted

PROJECT="ClassicBlockPuzzle.xcodeproj"
SCHEME="ClassicBlockPuzzle"
OUT_DIR="./screenshots"
LANGUAGES=("en" "zh-Hans" "ja" "ko" "es" "fr" "de" "pt-BR" "ru" "ar" "th" "vi" "id" "it" "tr")

mkdir -p "$OUT_DIR"

# Step 1: Build & install on each simulator
DEVICE_67="iPhone 15 Pro Max"   # 6.7"
DEVICE_65="iPhone 11 Pro Max"   # 6.5"
DEVICE_55="iPhone 8 Plus"       # 5.5"

for device in "$DEVICE_67"; do
    echo "=== Booting $device ==="
    xcrun simctl boot "$device" 2>/dev/null || true
    xcrun simctl install booted "$(find ~/Library/Developer/Xcode/DerivedData -name 'ClassicBlockPuzzle.app' | head -1)"
    
    # Step 2: Set language
    xcrun simctl spawn booted defaults write -g AppleLocale "en_US"
    xcrun simctl terminate booted com.classicblockpuzzle.ios
    
    # Step 3: Launch & capture
    xcrun simctl launch booted com.classicblockpuzzle.ios
    sleep 4
    
    # Screenshot
    xcrun simctl io booted screenshot "$OUT_DIR/67_en_$(date +%s).png"
done

echo "Done. Now use fastlane frameit or Figma to add device frames."
echo "Recommended tool: fastlane deliver for metadata + screenshot upload."
