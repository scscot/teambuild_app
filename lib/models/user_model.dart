// PATCHED: Added optional 'level' field to UserModel with support in all methods
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final DateTime createdAt;
  final String? city;
  final String? state;
  final String? country;
  final String? referredBy;
  final String? photoUrl;
  final int? level; // PATCHED

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.createdAt,
    this.city,
    this.state,
    this.country,
    this.referredBy,
    this.photoUrl,
    this.level, // PATCHED
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      city: json['city'],
      state: json['state'],
      country: json['country'],
      referredBy: json['referredBy'],
      photoUrl: json['photoUrl'],
      level: json['level'], // PATCHED
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'createdAt': createdAt.toIso8601String(),
      'city': city,
      'state': state,
      'country': country,
      'referredBy': referredBy,
      'photoUrl': photoUrl,
      'level': level, // PATCHED
    };
  }

  // PATCH START: Add support for copyWith including 'level'
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    DateTime? createdAt,
    String? city,
    String? state,
    String? country,
    String? referredBy,
    String? photoUrl,
    int? level,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      referredBy: referredBy ?? this.referredBy,
      photoUrl: photoUrl ?? this.photoUrl,
      level: level ?? this.level,
    );
  }
  // PATCH END
}
