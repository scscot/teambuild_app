#!/bin/bash

# Exit immediately if any command fails
set -e

echo "🧹 Cleaning Flutter and CocoaPods build artifacts..."

# Step 1: Clean Flutter build
flutter clean

# Step 2: Clear Xcode Derived Data
echo "🗑 Removing Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData

# Step 3: Delete CocoaPods artifacts
echo "🧼 Removing CocoaPods artifacts..."
cd ios
pod deintegrate
rm -rf Pods Podfile.lock Runner.xcworkspace
cd ..

# Step 4: Reinstall dependencies
echo "📦 Getting Flutter packages..."
flutter pub get

echo "📦 Installing CocoaPods..."
cd ios
pod install
cd ..

# Step 5: Build release
echo "🚀 Building iOS release..."
flutter build ios --release

echo "✅ Build process complete. Ready to archive in Xcode."
