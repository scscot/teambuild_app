#!/bin/bash

# Navigate to the root of the project regardless of where the script is run
cd "$(dirname "$0")/.."

# Remove old zip file if it exists
rm -f tbp_files.zip

# Create new zip archive with specified directories and files
zip -r tbp_files.zip \
lib/ \
assets/ \
scripts/ \
TeamBuild_Plus_Project_Updated.docx \
xcode_build_settings.txt \
xcode_build_core_settings.txt \
pubspec.yaml \
pubspec.lock \
ios/Podfile \
ios/Podfile.lock \
ios/Runner/GoogleService-Info.plist \
ios/Runner.xcworkspace/contents.xcworkspacedata \
ios/Runner.xcodeproj/project.pbxproj \
ios/Flutter/Generated.xcconfig \
ios/Flutter/Debug.xcconfig \
ios/Flutter/Release.xcconfig \
ios/Flutter/flutter_export_environment.sh

echo "✅ tbp_files.zip created successfully."
