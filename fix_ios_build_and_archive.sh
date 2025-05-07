#!/bin/bash

# Exit immediately on failure
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

# Step 5: Disable arm64 for simulator in Podfile (if not already done)
echo "⚙️ Disabling arm64 for simulator (M1/M2 Macs workaround)..."
if ! grep -q "post_install do" ios/Podfile; then
  cat <<EOF >> ios/Podfile

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
EOF
fi

# Step 6: Rebuild CocoaPods with updated Podfile
cd ios
pod install
cd ..

# Step 7: Build release
echo "🚀 Building iOS release..."
flutter build ios --release

# Step 8: Open Xcode for manual archive test
echo "📦 Opening Xcode for archive..."
open ios/Runner.xcworkspace

echo "✅ Build complete. Proceed to Product → Archive in Xcode."
