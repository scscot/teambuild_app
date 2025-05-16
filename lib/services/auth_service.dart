// SDK-BASED — auth_service.dart using Firebase Auth

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('✅ AuthService — Login success. UID: ${result.user?.uid}');
      return result.user;
    } catch (e) {
      print('❌ AuthService — Login failed: $e');
      rethrow;
    }
  }

  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      print('✅ AuthService — Registration success. UID: ${result.user?.uid}');
      return result.user;
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
