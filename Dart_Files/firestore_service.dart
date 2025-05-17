import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tbp/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbp/services/auth_service.dart';
import 'session_manager.dart';

class FirestoreService {
  final String projectId = 'teambuilder-plus-fe74d';
  final usersCollection = FirebaseFirestore.instance.collection('users');

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
        return results[0]['document'];
      }
    }
    return null;
  }

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
    String accessToken = SessionManager.instance.accessToken;
    if (accessToken.isEmpty) {
      debugPrint('⚠️ Missing access token. Attempting re-auth...');
      final email = SessionManager.instance.currentUser?.email;
      final password = await SessionManager.instance.getStoredPassword();

      if (email != null && password != null) {
        try {
          final success = await AuthService().signInWithEmailAndPassword(email, password);
          if (!success) throw Exception('AuthService signIn failed');

          accessToken = SessionManager.instance.accessToken;
          debugPrint('🔁 Firebase re-auth via AuthService complete.');
        } catch (e) {
          debugPrint('❌ Firebase re-auth via AuthService failed: $e');
          return null;
        }
      } else {
        debugPrint('❌ Cannot re-authenticate — missing email or password');
        return null;
      }
    }

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
        return UserModel.fromFirestore(fields, docId: uid);
      } else {
        debugPrint('❌ Failed to load user profile:');
        debugPrint(response.body);
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception fetching user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await usersCollection.doc(uid).update(data);
  }

  Future<void> ensureFirebaseAuthSession({required String email, required String password}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.email != email) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        debugPrint('✅ Firebase re-auth before Storage upload complete');
      } catch (e) {
        debugPrint('❌ Firebase re-auth before upload failed: $e');
      }
    } else {
      debugPrint('✅ FirebaseAuth session is already active');
    }
  }
}
