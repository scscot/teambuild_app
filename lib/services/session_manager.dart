import '../models/user_model.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() => _instance;

  SessionManager._internal();

  UserModel? _currentUser;

  void setCurrentUser(UserModel user) {
    _currentUser = user;
  }

  UserModel? get currentUser => _currentUser;

  bool isLoggedIn() => _currentUser != null;

  void clearSession() {
    _currentUser = null;
  }

  dynamic getHomeScreen() {
    // Placeholder for routing to the home screen, typically Dashboard
    throw UnimplementedError('Define getHomeScreen routing logic.');
  }
}
