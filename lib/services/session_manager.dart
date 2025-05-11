import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class SessionManager {
  static final SessionManager instance = SessionManager._internal();
  SessionManager._internal();

  UserModel? currentUser;
  String? _idToken;
  String? _accessToken;

  void persistUser(UserModel user) {
    currentUser = user;
  }

  void saveSession({
    required UserModel user,
    required String idToken,
    required String accessToken,
  }) {
    currentUser = user;
    _idToken = idToken;
    _accessToken = accessToken;
    saveToStorage();
    debugPrint('🧠 Session UID after save: ${currentUser?.uid}');
  }

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (currentUser != null) {
      await prefs.setString('uid', currentUser!.uid);
      await prefs.setString('email', currentUser!.email);
      await prefs.setString('fullName', currentUser!.fullName);
      await prefs.setString('city', currentUser!.city ?? '');
      await prefs.setString('state', currentUser!.state ?? '');
      await prefs.setString('country', currentUser!.country ?? '');
    }
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    final email = prefs.getString('email');
    final fullName = prefs.getString('fullName');
    final city = prefs.getString('city');
    final state = prefs.getString('state');
    final country = prefs.getString('country');

    if (uid != null && email != null && fullName != null) {
      currentUser = UserModel(
        uid: uid,
        email: email,
        fullName: fullName,
        createdAt: DateTime.now(),
        city: city,
        state: state,
        country: country,
      );
      debugPrint('🧠 Session restored for UID: $uid');
    }
  }

  String? get idToken => _idToken;
  String? get accessToken => _accessToken;

Future<void> clear() async {
  currentUser = null;
  _idToken = null;
  _accessToken = null;
}

  Future<void> signOut() async {
    clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
