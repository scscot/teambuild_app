// CLEAN PATCHED — auth_service.dart with login method returning UserModel

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserModel> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception('User ID not found after login');

      final user = await FirestoreService().getUser(uid);
      if (user == null) throw Exception('User profile not found in Firestore');

      return user;
    } catch (e) {
      print('❌ AuthService.login error: $e');
      rethrow;
    }
  }

  Future<UserModel> register(String email, String password, Map<String, dynamic> userMap) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception('User ID not found after registration');

      userMap['uid'] = uid;
      await FirestoreService().createUser(userMap);

      final user = await FirestoreService().getUser(uid);
      if (user == null) throw Exception('User profile not found after registration');

      return user;
    } catch (e) {
      print('❌ AuthService.register error: $e');
      rethrow;
    }
  }
}
