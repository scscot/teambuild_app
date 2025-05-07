#!/bin/bash

set -e

echo "📁 Backing up ios/ directory..."
[ -d ios ] && mv ios ios_backup_$(date +%s)

echo "🧹 Cleaning Flutter project and derived data..."
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "🛠️ Reinitializing iOS support..."
flutter create --org com.scott --platforms=ios .

echo "🔧 Restoring pubspec dependencies..."
flutter pub get

echo "⏳ Waiting for .flutter-plugins to be created..."
for i in {1..5}; do
  if [ -f .flutter-plugins ]; then
    echo "✅ .flutter-plugins found."
    break
  fi
  sleep 1
done

echo "📅 Restoring patched Podfile from scripts directory..."
cp -f scripts/Podfile ios/Podfile

echo "📦 Installing CocoaPods..."
cd ios
pod install --repo-update
cd ..

echo "✅ Done. Opening Runner.xcworkspace in Xcode..."
open ios/Runner.xcworkspace
