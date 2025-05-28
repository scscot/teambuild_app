#!/bin/bash

set -e
killall -9 Xcode 2>/dev/null || true
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

# Step 4: Update Bundle Identifier and Signing Config
echo "🆔 Setting Bundle Identifier to $BUNDLE_ID"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" ios/Runner/Info.plist

echo "🔏 Setting Code Signing Team and Style in project.pbxproj"
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" ios/Runner.xcodeproj/project.pbxproj
sed -i '' "s/CODE_SIGN_STYLE = .*/CODE_SIGN_STYLE = Automatic;/g" ios/Runner.xcodeproj/project.pbxproj
sed -i '' "s/DEVELOPMENT_TEAM = .*/DEVELOPMENT_TEAM = $DEVELOPMENT_TEAM;/g" ios/Runner.xcodeproj/project.pbxproj

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

echo "📦 Running initial pod install..."
if pod install --repo-update; then
  echo "✅ pod install completed successfully"
else
  echo "❌ Initial pod install failed. Trying pod repo update and retrying install..."
  if pod repo update && pod install; then
    echo "✅ pod install succeeded after repo update"
  else
    echo "❌ Second attempt failed. Reinstalling CocoaPods and trying again..."
    sudo gem install cocoapods
    if pod repo update && pod install; then
      echo "✅ pod install succeeded after reinstalling CocoaPods"
    else
      echo "❌ pod install still failing after all attempts. Exiting."
      exit 1
    fi
  fi
fi

# Ensure sandbox stays in sync for Xcode
if [ -d Pods ] && [ -f Podfile.lock ]; then
  if cp Podfile.lock Pods/Manifest.lock; then
    echo "📦 Synced Podfile.lock → Pods/Manifest.lock for sandbox consistency"
  else
    echo "❌ ERROR: Could not copy to Pods/Manifest.lock"
    ls -ld Pods
    ls -l Pods/Manifest.lock 2>/dev/null || echo "Manifest.lock not found"
    exit 1
  fi
else
  echo "⚠️ Cannot sync Manifest.lock — Pods/ directory or Podfile.lock missing"
  exit 1
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

echo "✅ Clean rebuild complete. Bundle ID set to $BUNDLE_ID. Team: $DEVELOPMENT_TEAM. Opened in Xcode for signing and archive."
