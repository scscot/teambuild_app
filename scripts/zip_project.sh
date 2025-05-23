#!/bin/bash

# Navigate to project directory
cd ~/Desktop/tbp || exit 1

# Remove existing ProjectFiles.zip if it exists
rm -f ProjectFiles.zip

# Zip specified Dart files into ProjectFiles.zip
zip ProjectFiles.zip \
  lib/main.dart \
  lib/services/auth_service.dart \
  lib/services/session_manager.dart \
  lib/services/firestore_service.dart \
  lib/services/biometric_auth_service.dart \
  lib/screens/login_screen.dart \
  lib/screens/new_registration_screen.dart \
  lib/screens/dashboard_screen.dart \
  lib/screens/profile_screen.dart \
  lib/screens/edit_profile_screen.dart \
  lib/screens/share_screen.dart \
  lib/screens/downline_team_screen.dart \
  lib/screens/member_detail_screen.dart \
  lib/screens/template_screen.dart \
  lib/models/user_model.dart \
  lib/data/states_by_country.dart \
  lib/widgets/header_widgets.dart \
  pubspec.yaml \
  ios/Podfile