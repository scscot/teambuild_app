import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  UserModel? _currentUser;
  static const _userKey = 'currentUser';
  static const _biometricKey = 'biometricEnabled';

  Future<void> setCurrentUser(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(user.toMap());
    await prefs.setString(_userKey, jsonString);
    print('🧩 SessionManager.setCurrentUser called — User UID: ${user.uid}');
    print('📦 SessionManager saved user JSON: $jsonString');
  }

  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data != null) {
      print('📦 SessionManager — raw stored user data: $data');
      try {
        _currentUser = UserModel.fromMap(jsonDecode(data));
      } catch (e) {
        print('❌ SessionManager — failed to decode user: $e');
      }
    } else {
      print('❌ SessionManager — no stored user data found');
    }
    return _currentUser;
  }

  UserModel? get currentUser => _currentUser;

  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  void clearSession() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
  }

  Future<bool> get biometricEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }
}
