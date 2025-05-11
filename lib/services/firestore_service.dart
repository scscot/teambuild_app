// FINAL PATCHED: firestore_service.dart — Fully preserved + getUserProfileById()

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tbp/models/user_model.dart';

class FirestoreService {
  final String projectId = 'teambuilder-plus-fe74d';

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
        final doc = results[0]['document'];
        final fields = doc['fields'] as Map<String, dynamic>;
        return fields.map((key, value) => MapEntry(key, value['stringValue'] ?? ''));
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
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        debugPrint('📥 Fetched Firestore doc for UID: $uid => ${doc.data()}');
        return UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('❌ Error in getUserProfileById: $e');
    }
    return null;
  }
}
