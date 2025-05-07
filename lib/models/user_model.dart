// FINAL PATCHED: user_model.dart — Uses DateTime for createdAt

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final DateTime createdAt;
  final String? photoUrl;
  final String? referredBy;
  final String? referredByName;
  final String? level;
  final String? city;
  final String? state;
  final String? country;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.createdAt,
    this.photoUrl,
    this.referredBy,
    this.referredByName,
    this.level,
    this.city,
    this.state,
    this.country,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      photoUrl: json['photoUrl'],
      referredBy: json['referredBy'],
      referredByName: json['referredByName'],
      level: json['level'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'createdAt': createdAt.toIso8601String(),
      'photoUrl': photoUrl,
      'referredBy': referredBy,
      'referredByName': referredByName,
      'level': level,
      'city': city,
      'state': state,
      'country': country,
    };
  }
} 
