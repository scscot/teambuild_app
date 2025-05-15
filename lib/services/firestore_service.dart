// FINAL PATCHED: firestore_service.dart — Fully preserved + getUserProfileById()

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tbp/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'session_manager.dart';

class FirestoreService {
  final String projectId = 'teambuilder-plus-fe74d';
  final usersCollection = FirebaseFirestore.instance.collection('users');

  // PATCH START: Return full Firestore document for proper parsing
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents:runQuery',
    );

    final body = {
      "structuredQuery": {
        "from": [{"collectionId": "users"}],
        "where": {
          "fieldFilter": {
            "field": {"fieldPath": "email"},
            "op": "EQUAL",
            "value": {"stringValue": email},
          }
        },
        "limit": 1
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final results = json.decode(response.body);
      if (results is List && results.isNotEmpty && results[0]['document'] != null) {
        return results[0]['document']; // return full document for parsing
      }
    }
    return null;
  }
  // PATCH END

  Future<Map<String, dynamic>?> getUserProfileByReferralCode(String referralCode) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents:runQuery',
    );

    final body = {
      "structuredQuery": {
        "from": [{"collectionId": "users"}],
        "where": {
          "fieldFilter": {
            "field": {"fieldPath": "referralCode"},
            "op": "EQUAL",
            "value": {"stringValue": referralCode},
          }
        },
        "limit": 1
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final results = json.decode(response.body);
      if (results is List && results.isNotEmpty && results[0]['document'] != null) {
        final doc = results[0]['document'];
        final fields = doc['fields'] as Map<String, dynamic>;
        return fields.map((key, value) => MapEntry(key, value['stringValue'] ?? ''));
      }
    }
    return null;
  }

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String country,
    required String state,
    required String city,
    String? referredBy,
  }) async {
    final referralCode = email.hashCode.toRadixString(36).toUpperCase().substring(0, 6);

    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users?documentId=$uid',
    );

    final body = json.encode({
      "fields": {
        "email": {"stringValue": email},
        "fullName": {"stringValue": fullName},
        "country": {"stringValue": country},
        "state": {"stringValue": state},
        "city": {"stringValue": city},
        "referralCode": {"stringValue": referralCode},
        if (referredBy != null)
          "referredBy": {"stringValue": referredBy},
      }
    });

    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
  }

  Future<UserModel?> getUserProfileById(String uid) async {
    final accessToken = SessionManager.instance.accessToken;
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/teambuilder-plus-fe74d/databases/(default)/documents/users/$uid',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fields = data['fields'] as Map<String, dynamic>;
        return UserModel.fromFirestore(fields);
      } else {
        print('❌ Failed to load user profile: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception fetching user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await usersCollection.doc(uid).update(data);
  }

  // PATCH START: Ensure FirebaseAuth context exists for upload
  Future<void> ensureFirebaseAuthSession({required String email, required String password}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.email != email) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        debugPrint('✅ Firebase re-auth before Storage upload complete');
      } catch (e) {
        debugPrint('❌ Firebase re-auth before upload failed: \$e');
      }
    } else {
      debugPrint('✅ FirebaseAuth session is already active');
    }
  }
  // PATCH END
}
