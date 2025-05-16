// PATCHED — firestore_service.dart with uid validation and diagnostics for updateUser

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(Map<String, dynamic> userMap) async {
    final String uid = userMap['uid'];
    await _firestore.collection('users').doc(uid).set(userMap);
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    if (uid.isEmpty) {
      print('❌ FirestoreService.updateUser — UID is empty. Cannot update user.');
      throw ArgumentError('User ID cannot be empty');
    }
    print('📡 FirestoreService.updateUser — Updating UID: $uid');
    print('📦 Update Payload: $updates');
    await _firestore.collection('users').doc(uid).update(updates);
  }

  Future<String> getUserFullName(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return 'N/A';

      if (data['fullName'] != null && data['fullName'] is String) {
        return data['fullName'];
      } else if (data['firstName'] != null && data['lastName'] != null) {
        return '${data['firstName']} ${data['lastName']}';
      } else {
        return 'N/A';
      }
    } catch (e) {
      print('❌ Error retrieving user full name: $e');
      return 'N/A';
    }
  }

  Future<List<UserModel>> getDownlineUsers(String referredBy) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('referredBy', isEqualTo: referredBy)
        .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }
}
