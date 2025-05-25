#!/bin/bash

# Navigate to project directory
cd ~/Desktop/tbp || exit 1

# Remove existing ProjectFiles.zip if it exists
rm -f ProjectFiles.zip

# Zip specified Dart files into ProjectFiles.zip
zip ProjectFiles.zip \
  lib/services/* \
  lib/screens/* \
  lib/models/* \
  lib/data/states_by_country.dart \
  lib/widgets/* \
  lib/main.dart \
  pubspec.yaml \
  ios/Podfile
