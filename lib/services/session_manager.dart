// PATCHED — session_manager.dart with implemented getHomeScreen method

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/dashboard_screen.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() => _instance;

  SessionManager._internal();

  UserModel? currentUser;

  bool isLoggedIn() => currentUser != null;

  void setCurrentUser(UserModel user) {
    currentUser = user;
  }

  Widget getHomeScreen() {
    return const DashboardScreen();
  }
}
