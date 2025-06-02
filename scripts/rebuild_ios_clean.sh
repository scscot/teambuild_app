#!/bin/bash

set -e
SRC_DIR=~/Desktop/tbp
BUNDLE_ID="com.scott.teambuildApp"
IOS_DIR="$SRC_DIR/ios"
BUILD_MODE="development"  # Change to 'production' if needed

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

# Step 3: Recreate ios/ and restore essential files
flutter create --org com.scott --platforms=ios .

# Step 4: Set Bundle Identifier in project.pbxproj
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" ios/Runner.xcodeproj/project.pbxproj

# ✅ Confirm patch success
if grep -q "$BUNDLE_ID" ios/Runner.xcodeproj/project.pbxproj; then
  echo "✅ Bundle ID successfully set in project.pbxproj"
else
  echo "❌ Bundle ID patch may have failed in project.pbxproj"
fi

# Step 4.1: Patch Info.plist with correct Bundle ID
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" ios/Runner/Info.plist || echo "⚠️ Failed to set Bundle ID in Info.plist (may already be set)"

# Step 5: Restore configuration files
cp scripts/Info.plist ios/Runner/Info.plist
cp scripts/Podfile ios/Podfile
cp scripts/Debug.xcconfig ios/Flutter/Debug.xcconfig
cp scripts/Release.xcconfig ios/Flutter/Release.xcconfig
cp scripts/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist

# Step 5.1: Dynamically create Runner.entitlements
cat <<EOF > ios/Runner/Runner.entitlements
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>aps-environment</key>
  <string>$BUILD_MODE</string>
  <key>UIBackgroundModes</key>
  <array>
    <string>remote-notification</string>
  </array>
</dict>
</plist>
EOF

echo "✅ Runner.entitlements written with aps-environment = $BUILD_MODE"

# Step 6: Restore Dart dependencies and CocoaPods
flutter pub get
cd ios
pod install --repo-update

# Step 7: Optional - Sync Manifest.lock
if [ -f Podfile.lock ]; then
  mkdir -p Pods
  cp Podfile.lock Pods/Manifest.lock
  echo "📦 Synced Podfile.lock → Pods/Manifest.lock"
fi

# Step 8: Open in Xcode (workspace only)
cd "$SRC_DIR"
open ios/Runner.xcworkspace

echo "✅ Rebuild complete. Bundle ID: $BUNDLE_ID"
