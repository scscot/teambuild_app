// FINAL PATCHED — user_model.dart with city, sponsor counts, and role (string-based)

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? country;
  final String? state;
  final String? city;
  final String? referralCode;
  final String? referredBy;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? joined;
  final int? level;
  final int? directSponsorCount;
  final int? totalTeamCount;
  final String? role; // PATCHED: use role string instead of isAdmin bool

  UserModel({
    required this.uid,
    required this.email,
    this.firstName,
    this.lastName,
    this.country,
    this.state,
    this.city,
    this.referralCode,
    this.referredBy,
    this.photoUrl,
    this.createdAt,
    this.joined,
    this.level,
    this.directSponsorCount,
    this.totalTeamCount,
    this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'country': country,
      'state': state,
      'city': city,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'joined': joined?.toIso8601String(),
      'level': level,
      'directSponsorCount': directSponsorCount,
      'totalTeamCount': totalTeamCount,
      'role': role, // PATCHED
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'],
      lastName: map['lastName'],
      country: map['country'],
      state: map['state'],
      city: map['city'],
      referralCode: map['referralCode'],
      referredBy: map['referredBy'],
      photoUrl: map['photoUrl'],
      createdAt: _parseTimestamp(map['createdAt']),
      joined: _parseTimestamp(map['joined']),
      level: map['level'],
      directSponsorCount: map['directSponsorCount'],
      totalTeamCount: map['totalTeamCount'],
      role: map['role'], // PATCHED
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? country,
    String? state,
    String? city,
    String? referralCode,
    String? referredBy,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? joined,
    int? level,
    int? directSponsorCount,
    int? totalTeamCount,
    String? role, // PATCHED
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      joined: joined ?? this.joined,
      level: level ?? this.level,
      directSponsorCount: directSponsorCount ?? this.directSponsorCount,
      totalTeamCount: totalTeamCount ?? this.totalTeamCount,
      role: role ?? this.role, // PATCHED
    );
  }
}
