// FINAL PATCHED: session_manager.dart — Includes signOut method for ProfileScreen compatibility

import '../models/user_model.dart';

class SessionManager {
  static final SessionManager instance = SessionManager._internal();

  SessionManager._internal();

  UserModel? currentUser;
  String? _idToken;
  String? _accessToken;

  void saveSession({
    required UserModel user,
    required String idToken,
    required String accessToken,
  }) {
    currentUser = user;
    _idToken = idToken;
    _accessToken = accessToken;
  }

  String? get idToken => _idToken;
  String? get accessToken => _accessToken;

  void clear() {
    currentUser = null;
    _idToken = null;
    _accessToken = null;
  }

  Future<void> signOut() async {
    clear();
  }
} 
