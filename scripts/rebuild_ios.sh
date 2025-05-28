#!/bin/bash

set -e
killall -9 Xcode || true
SRC_DIR=~/Desktop/tbp
BUNDLE_ID="com.scott.teambuildApp"
DEVELOPMENT_TEAM="YXV25WMDS8"
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

cp scripts/Info.plist ios/Runner/Info.plist

# Step 4: Update Bundle Identifier and Team in Info.plist and project.pbxproj
echo "🆔 Setting Bundle Identifier to $BUNDLE_ID"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" ios/Runner/Info.plist
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" ios/Runner.xcodeproj/project.pbxproj
sed -i '' "s/DEVELOPMENT_TEAM = .*/DEVELOPMENT_TEAM = $DEVELOPMENT_TEAM;/g" ios/Runner.xcodeproj/project.pbxproj
sed -i '' "s/CODE_SIGN_STYLE = .*/CODE_SIGN_STYLE = Automatic;/g" ios/Runner.xcodeproj/project.pbxproj

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
pod install --repo-update || {
  echo "⚠️ Initial pod install failed, retrying..."
  pod repo update && pod install
}

# ✅ Post-install check — Manifest.lock must exist
if [ -f Pods/Manifest.lock ]; then
  echo "✅ CocoaPods sandbox synced correctly."
else
  echo "❌ ERROR: Manifest.lock missing — pod install may have failed."
  echo "📦 Retrying pod repo update and install..."
  pod repo update && pod install

  # Final check
  if [ -f Pods/Manifest.lock ]; then
    echo "✅ CocoaPods sandbox synced after retry."
  else
    echo "❌ FATAL: Still no Manifest.lock — CocoaPods may be broken. Manual inspection required."
    exit 1
  fi
fi

cd ..

cp scripts/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist

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

# Step 10: Open Xcode
open ios/Runner.xcworkspace

echo "✅ Clean rebuild complete. Bundle ID set to $BUNDLE_ID. Opened in Xcode for signing and archive."
