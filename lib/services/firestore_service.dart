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

  // PATCH START: Add single-field update method
  Future<void> updateUserField(String uid, String field, dynamic value) async {
    try {
      await _firestore.collection('users').doc(uid).update({field: value});
      print('✅ Firestore field "$field" updated successfully for user $uid');
    } catch (e) {
      print('❌ Failed to update field "$field" for user $uid: $e');
      rethrow;
    }
  }
  // PATCH END

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

  Future<String> getSponsorNameByReferralCode(String referralCode) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final data = userQuery.docs.first.data();
        if (data['fullName'] != null && data['fullName'] is String) {
          return data['fullName'];
        } else if (data['firstName'] != null && data['lastName'] != null) {
          return '${data['firstName']} ${data['lastName']}';
        }
      }
      return 'N/A';
    } catch (e) {
      print('❌ Error retrieving sponsor name by referralCode: $e');
      return 'N/A';
    }
  }

  // PATCH START: Add missing method to fetch user by referralCode
  Future<UserModel?> getUserByReferralCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(snapshot.docs.first);
      }
    } catch (e) {
      print('❌ Error in getUserByReferralCode: $e');
    }
    return null;
  }
  // PATCH END

  // PATCH START: Upline counter traversal
  Future<void> incrementUplineCounts(String referralCode) async {
    String? currentCode = referralCode;
    final visited = <String>{};

    while (currentCode != null && !visited.contains(currentCode)) {
      visited.add(currentCode);
      final snapshot = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: currentCode)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) break;

      final doc = snapshot.docs.first;
      final data = doc.data();
      final uid = doc.id;
      final isDirect = visited.length == 1;

      final updates = <String, dynamic>{};
      if (isDirect) updates['direct_sponsor_count'] = FieldValue.increment(1);
      updates['total_team_count'] = FieldValue.increment(1);

      await _firestore.collection('users').doc(uid).update(updates);

      currentCode = data['referredBy'];
    }
  }
  // PATCH END
} 
