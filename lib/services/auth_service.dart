// FINAL PATCHED — auth_service.dart with UserModel hydration

import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserModel> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final uid = result.user?.uid;
      if (uid == null) throw Exception('User ID not found after login.');

      final user = await FirestoreService().getUser(uid);
      if (user == null) throw Exception('User not found in Firestore.');

      print('✅ AuthService — Login success. UID: $uid');
      return user;
    } catch (e) {
      print('❌ AuthService — Login failed: $e');
      rethrow;
    }
  }

  Future<UserModel> register(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final uid = result.user?.uid;
      if (uid == null) throw Exception('User ID not found after registration.');

      final user = await FirestoreService().getUser(uid);
      if (user == null)
        throw Exception('User not found in Firestore after registration.');

      print('✅ AuthService — Registration success. UID: $uid');
      return user;
    } catch (e) {
      print('❌ AuthService — Registration failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    print('👋 AuthService — User signed out');
  }
}
