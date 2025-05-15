#!/bin/bash

cd "$(dirname "$0")/.."
rm -f tbp_files.zip
zip -r tbp_files.zip \
lib/models/ \
lib/screens/ \
lib/data/ \
lib/services/ \
lib/main.dart \
pubspec.yaml

echo "✅ tbp_files.zip created successfully."
