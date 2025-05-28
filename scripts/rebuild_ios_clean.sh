#!/bin/bash

set -e
killall -9 Xcode || true
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

cp scripts/Info.plist ios/Runner/Info.plist

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

# Step 7.5: Regenerate Manifest.lock after pods install
if [ -f Podfile.lock ]; then
  mkdir -p Pods
  cp Podfile.lock Pods/Manifest.lock
  echo "📦 Synced Podfile.lock → Pods/Manifest.lock for sandbox consistency"
else
  echo "⚠️ Podfile.lock not found. Pod install may have failed."
fi

cd ..

cp scripts/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist

# Step 8: Regenerate .packages if missing
if [ ! -f .packages ]; then
  echo "📦 Regenerating .packages from package_config.json"
  if command -v jq &>/dev/null; then
    cat .dart_tool/package_config.json | jq -r '.packages[] | "\(.name):file://\(.rootUri)/"' > .packages
  else
    echo "⚠️ 'jq' not found. Skipping .packages regeneration."
  fi
fi

# Step 9: Ensure GoogleService-Info.plist is included in Xcode project build phase
echo "📲 Ensuring GoogleService-Info.plist is added to Xcode build phase..."

GOOGLE_PLIST_PATH="ios/Runner/GoogleService-Info.plist"
XCODE_PROJECT_PATH="ios/Runner.xcodeproj/project.pbxproj"

if [ -f "$GOOGLE_PLIST_PATH" ]; then
  UUID_FILE_REF=$(uuidgen)
  UUID_BUILD_FILE=$(uuidgen)
  FILE_REF="        $UUID_FILE_REF /* GoogleService-Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = GoogleService-Info.plist; sourceTree = \"<group>\"; };"
  BUILD_FILE="        $UUID_BUILD_FILE /* GoogleService-Info.plist in Resources */ = {isa = PBXBuildFile; fileRef = $UUID_FILE_REF /* GoogleService-Info.plist */; };"

  echo "📎 Adding file reference and build file to project.pbxproj..."

  # Only patch if not already present
  if ! grep -q "GoogleService-Info.plist" "$XCODE_PROJECT_PATH"; then
    sed -i '' "/Begin PBXFileReference section/,/End PBXFileReference section/ s|^.*End PBXFileReference section|$FILE_REF\
    End PBXFileReference section|" "$XCODE_PROJECT_PATH"

    sed -i '' "/Begin PBXBuildFile section/,/End PBXBuildFile section/ s|^.*End PBXBuildFile section|$BUILD_FILE\
    End PBXBuildFile section|" "$XCODE_PROJECT_PATH"

    echo "✅ GoogleService-Info.plist added to Xcode project references."
  else
    echo "ℹ️ GoogleService-Info.plist already included in project."
  fi
else
  echo "❌ GoogleService-Info.plist not found at expected path: $GOOGLE_PLIST_PATH"
fi

# Step 10: Open Xcode
# open ios/Runner.xcworkspace

echo "✅ Clean rebuild complete. Bundle ID set to $BUNDLE_ID. Opened in Xcode for signing and archive."
