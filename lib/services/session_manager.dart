import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

class SessionManager {
  static const String _userKey = 'user';
  static const String _biometricKey = 'biometric_enabled';
  static const String _logoutTimeKey = 'last_logout_time';

  // PATCH START: Unified and debug-enhanced session setter
  Future<void> setCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userMap = jsonEncode(user.toMap());
    await prefs.setString(_userKey, userMap);
    print('📂 SessionManager — User session saved with UID: ${user.uid}');
  }
  // PATCH END

  // PATCH START: Hydrated session reader with UID verification
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData == null) {
      print('⚠️ SessionManager — No session data found');
      return null;
    }
    try {
      final map = jsonDecode(userData);
      final user = UserModel.fromMap(map);
      if (user.uid.isEmpty) {
        print('⚠️ SessionManager — Decoded user has empty UID');
        return null;
      }
      print('✅ SessionManager — User hydrated: ${user.uid}');
      return user;
    } catch (e) {
      print('❌ Failed to decode user session: $e');
      return null;
    }
  }
  // PATCH END

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    print('🩹 Session cleared — biometric flag preserved');
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
    print('🟢 Biometric preference saved: $enabled');
  }

  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  Future<void> setLogoutTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_logoutTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> isLogoutCooldownActive(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_logoutTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - timestamp < seconds * 1000;
  }
}
