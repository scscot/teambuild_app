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

# Step 3: Recreate iOS directory
flutter create --org com.scott --platforms=ios .

# Step 4: Replace Info.plist
cp scripts/Info.plist ios/Runner/Info.plist

# Step 5: Update Bundle ID and Team ID in Xcode project
echo "🆔 Setting Bundle Identifier and Team ID"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" ios/Runner/Info.plist
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" ios/Runner.xcodeproj/project.pbxproj
sed -i '' "s/DEVELOPMENT_TEAM = .*/DEVELOPMENT_TEAM = $DEVELOPMENT_TEAM;/g" ios/Runner.xcodeproj/project.pbxproj
sed -i '' "s/CODE_SIGN_STYLE = .*/CODE_SIGN_STYLE = Automatic;/g" ios/Runner.xcodeproj/project.pbxproj

# Step 6: Restore Dart dependencies
flutter pub get

# Step 7: Restore CocoaPods config
cp scripts/Podfile ios/Podfile
cp scripts/Debug.xcconfig ios/Flutter/Debug.xcconfig
cp scripts/Release.xcconfig ios/Flutter/Release.xcconfig
cp scripts/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist

# Step 8: CocoaPods full reinstall
cd ios
pod deintegrate
if ! pod install --repo-update; then
  echo "⚠️ Initial pod install failed. Retrying..."
  pod repo update
  pod install --repo-update
fi

# Step 9: Recreate Manifest.lock for Xcode build consistency
if [ -f Podfile.lock ]; then
  echo "📦 Ensuring Pods/Manifest.lock exists..."
  mkdir -p Pods
  cp Podfile.lock Pods/Manifest.lock
  echo "✅ CocoaPods sandbox synced correctly."
else
  echo "❌ Podfile.lock missing — pod install may have failed."
fi

cd ..

# Step 10: Final clean and open Xcode
flutter clean
flutter pub get

open ios/Runner.xcworkspace

echo "✅ Clean rebuild complete. Bundle ID: $BUNDLE_ID | Team ID: $DEVELOPMENT_TEAM"
