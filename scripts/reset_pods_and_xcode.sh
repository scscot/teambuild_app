#!/bin/bash

set -e

# Kill Xcode if open
killall -9 Xcode || true

# Define project root
PROJECT_DIR=~/Desktop/tbp
cd "$PROJECT_DIR"

# Step 1: Remove stale build artifacts
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/Runner.xcworkspace
rm -rf ios/.symlinks

# Step 2: Reinstall CocoaPods
cd ios
pod install --repo-update
cd ..

# Step 3: Clean Flutter artifacts
flutter clean
flutter pub get

# Step 4: Reopen workspace in Xcode
open ios/Runner.xcworkspace

echo "✅ CocoaPods reset complete. Opened clean Xcode workspace. Now run: Product > Clean Build Folder → Product > Archive"
