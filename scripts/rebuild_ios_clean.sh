#!/bin/bash

set -e
killall -9 Xcode
SRC_DIR=~/Desktop/tbp
BUNDLE_ID="com.scott.teambuildApp"
echo "📁 Starting clean rebuild in: $SRC_DIR"

# Step 1: Backup and remove ios/
echo "🧼 Backing up ios/ → ios_backup_$(date +%s)"
mv "$SRC_DIR/ios" "$SRC_DIR/ios_backup_$(date +%s)"

# Step 2: Clean Flutter and Xcode
cd "$SRC_DIR"
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Step 3: Recreate iOS directory with initial org
flutter create --org com.scott --platforms=ios .

# Step 4: Update Bundle Identifier in Info.plist and project.pbxproj
echo "🆔 Setting Bundle Identifier to $BUNDLE_ID"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" ios/Runner/Info.plist
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" ios/Runner.xcodeproj/project.pbxproj

# Step 5: Restore Dart dependencies
flutter pub get

# Step 6: Restore Podfile and xcconfig
cp scripts/Podfile ios/Podfile
cp scripts/Debug.xcconfig ios/Flutter/Debug.xcconfig
cp scripts/Release.xcconfig ios/Flutter/Release.xcconfig

# Step 7: Full CocoaPods reset and reinstall
cd ios
rm -rf Pods
rm -rf Pods/Manifest.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.podspec
rm -rf Runner.xcworkspace
pod deintegrate
pod install --repo-update
cd ..

# Step 8: Final Dart clean & metadata regeneration
flutter clean
flutter pub get

# Step 9: Regenerate .packages if missing
if [ ! -f .packages ]; then
  echo "📦 Regenerating .packages from package_config.json"
  if command -v jq &>/dev/null; then
    cat .dart_tool/package_config.json | jq -r '.packages[] | "\(.name):file://\(.rootUri)/"' > .packages
  else
    echo "⚠️ 'jq' not found. Skipping .packages regeneration."
  fi
fi

# Step 9.5: Force Manifest.lock creation for Xcode sandbox sync
mkdir -p "$SRC_DIR/ios/Pods"
echo "🔍 Checking write access to: $SRC_DIR/ios/Pods/Manifest.lock"
touch "$SRC_DIR/ios/Pods/Manifest.lock" && rm "$SRC_DIR/ios/Pods/Manifest.lock"

if [ $? -eq 0 ]; then
  echo "📦 Copying Podfile.lock → Pods/Manifest.lock..."
  cp "$SRC_DIR/ios/Podfile.lock" "$SRC_DIR/ios/Pods/Manifest.lock"
else
  echo "❌ ERROR: No write permission to create Manifest.lock in $SRC_DIR/ios/Pods/"
  ls -ld "$SRC_DIR/ios/Pods"
fi

# Step 10: Open Xcode
open ios/Runner.xcworkspace

echo "✅ Clean rebuild complete. Bundle ID set to $BUNDLE_ID. Opened in Xcode for signing and archive."
