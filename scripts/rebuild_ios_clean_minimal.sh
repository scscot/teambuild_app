#!/bin/bash

set -e
SRC_DIR=~/Desktop/tbp
BUNDLE_ID="com.scott.teambuildApp"
IOS_DIR="$SRC_DIR/ios"

echo "📁 Starting clean iOS rebuild in: $SRC_DIR"

# Step 1: Quit Xcode and back up current ios/
killall -9 Xcode || true
BACKUP_NAME="ios_backup_$(date +%s)"
echo "🧼 Backing up ios/ → $BACKUP_NAME"
mv "$IOS_DIR" "$SRC_DIR/$BACKUP_NAME"

# Step 2: Clean Flutter & DerivedData
cd "$SRC_DIR"
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Step 3: Recreate ios/ and restore Info.plist, Podfile, xcconfig
flutter create --org com.scott --platforms=ios .

cp scripts/Info.plist ios/Runner/Info.plist
cp scripts/Podfile ios/Podfile
cp scripts/Debug.xcconfig ios/Flutter/Debug.xcconfig
cp scripts/Release.xcconfig ios/Flutter/Release.xcconfig
cp scripts/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist

# Step 4: Restore Dart deps and CocoaPods
flutter pub get
cd ios
pod install --repo-update

# Step 5: Optional - Sync Manifest.lock
if [ -f Podfile.lock ]; then
  mkdir -p Pods
  cp Podfile.lock Pods/Manifest.lock
  echo "📦 Synced Podfile.lock → Pods/Manifest.lock"
fi

# Step 6: Open in Xcode (workspace only)
cd "$SRC_DIR"
open ios/Runner.xcworkspace

echo "✅ Rebuild complete. Bundle ID: $BUNDLE_ID"
