// CLEAN PATCHED — auth_service.dart with FirebaseAuth login and register logic

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'session_manager.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) return false;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final user = UserModel.fromFirestore(doc);
      await SessionManager().saveUser(user);
      return true;
    } catch (e) {
      print('❌ Login error: \$e');
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) return false;

      final user = UserModel(
        uid: uid,
        email: email,
        firstName: '',
        lastName: '',
        city: '',
        state: '',
        country: '',
        referralCode: '',
        referredBy: '',
        photoUrl: '',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(user.toMap());
      await SessionManager().saveUser(user);
      return true;
    } catch (e) {
      print('❌ Registration error: \$e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await SessionManager().clearSession();
  }
}    
