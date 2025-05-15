// PATCHED: session_manager.dart — Fixed nullable String issue for FirebaseAuth sign-in
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tbp/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionManager {
  static final SessionManager instance = SessionManager._();
  SessionManager._();

  late SharedPreferences _prefs;
  UserModel? currentUser;
  String? _idToken;
  String? _accessToken;

  Future<void> loadFromStorage() async {
    _prefs = await SharedPreferences.getInstance();

    final rawJson = _prefs.getString('user_model');
    if (rawJson != null) {
      final map = json.decode(rawJson);
      currentUser = UserModel(
        uid: map['uid'] ?? '',
        email: map['email'],
        fullName: map['fullName'],
        country: map['country'],
        state: map['state'],
        city: map['city'],
        photoUrl: map['photoUrl'],
        referralCode: map['referralCode'],
        referredBy: map['referredBy'],
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      );
    }

    _idToken = _prefs.getString('idToken');
    _accessToken = _prefs.getString('accessToken');
  }

  Future<void> persistUser(UserModel user, {String? password}) async {
    currentUser = user;
    await _prefs.setString('uid', user.uid);
    await _prefs.setString('email', user.email ?? '');
    await _prefs.setString('fullName', user.fullName ?? '');
    await _prefs.setString('country', user.country ?? '');
    await _prefs.setString('state', user.state ?? '');
    await _prefs.setString('city', user.city ?? '');
    await _prefs.setString('user_model', json.encode(user.toJson()));
    if (password != null) await _prefs.setString('user_password', password);
  }

  Future<String?> getStoredPassword() async => _prefs.getString('user_password');

  Future<void> saveSession({
    required UserModel user,
    required String idToken,
    required String accessToken,
  }) async {
    currentUser = user;
    _idToken = idToken;
    _accessToken = accessToken;

    await _prefs.setString('user_model', json.encode(user.toJson()));
    await _prefs.setString('idToken', idToken);
    await _prefs.setString('accessToken', accessToken);
  }

  String get idToken => _idToken ?? '';
  String get accessToken => _accessToken ?? '';

  Future<void> signOut() async {
    currentUser = null;
    _idToken = null;
    _accessToken = null;
    await _prefs.clear();
  }

  Future<void> reauthenticate(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, // ✅ PATCHED: ensure non-null at call site
        password: password,
      );
      debugPrint('✅ Firebase re-auth completed inside SessionManager');
    } catch (e) {
      debugPrint('⚠️ Firebase re-auth failed inside SessionManager: $e');
    }
  }

  Map<String, String> get storageSnapshot =>
      Map.fromEntries(_prefs.getKeys().map((key) => MapEntry(key, _prefs.getString(key) ?? '')));
}
