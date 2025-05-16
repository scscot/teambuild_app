// SDK-BASED — session_manager.dart for managing logged-in user state

import '../models/user_model.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  UserModel? currentUser;

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  void setCurrentUser(UserModel user) {
    print('🧩 SessionManager.setCurrentUser called — User UID: ${user.uid}');
    currentUser = user;
  }

  bool isLoggedIn() {
    return currentUser != null;
  }

  UserModel? getUser() {
    return currentUser;
  }

  void clearSession() {
    print('🔒 SessionManager — Clearing session');
    currentUser = null;
  }

  dynamic getHomeScreen() {
    throw UnimplementedError('Define getHomeScreen routing logic.');
  }
}
