// CLEAN PATCH — session_manager.dart updated for Option B: UID fallback validation

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SessionManager {
  static const _userKey = 'user';
  static const _biometricKey = 'biometric_enabled';

  Future<void> setCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toMap());
    print('🧩 SessionManager.setCurrentUser called — User UID: \${user.uid}');
    await prefs.setString(_userKey, userJson);
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) {
      print('❌ SessionManager — no stored user data found');
      return null;
    }

    try {
      final userMap = jsonDecode(userJson);
      final user = UserModel.fromMap(userMap);
      if (user.uid.isEmpty) {
        print('❌ SessionManager — stored user UID is empty. Treating as invalid.');
        return null;
      }
      return user;
    } catch (e) {
      print('❌ SessionManager — error decoding user data: \$e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_biometricKey);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
  }

  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }
}
