import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

class SessionManager {
  static const String _userKey = 'user';
  static const String _biometricKey = 'biometric_enabled';

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }

  Future<void> setCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userMap = jsonEncode(user.toMap());
    await prefs.setString(_userKey, userMap);
    print('💾 SessionManager — User session saved');
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData == null) return null;
    try {
      return UserModel.fromMap(jsonDecode(userData));
    } catch (e) {
      print('❌ Failed to decode user session: $e');
      return null;
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    print('🧹 Session cleared — biometric flag preserved');
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

  // PATCH START: Logout cooldown mechanism
  static const String _logoutTimeKey = 'last_logout_time';

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
  // PATCH END
}
