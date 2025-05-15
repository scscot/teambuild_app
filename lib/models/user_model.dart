// PATCHED: fromFirestore now accepts optional docId to restore UID from document path
class UserModel {
  final String uid;
  final String? email;
  final String? fullName;
  final String? country;
  final String? state;
  final String? city;
  final String? photoUrl;
  final String? referralCode;
  final String? referredBy;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    this.email,
    this.fullName,
    this.country,
    this.state,
    this.city,
    this.photoUrl,
    this.referralCode,
    this.referredBy,
    this.createdAt,
  });

  // PATCH START: Add optional docId param to reliably populate uid
  factory UserModel.fromFirestore(Map<String, dynamic> fields, {String? docId}) {
    try {
      final uid = docId ?? fields['uid']?['stringValue'] ?? '';
      return UserModel(
        uid: uid,
        email: fields['email']?['stringValue'],
        fullName: fields['fullName']?['stringValue'],
        country: fields['country']?['stringValue'],
        state: fields['state']?['stringValue'],
        city: fields['city']?['stringValue'],
        photoUrl: fields['photoUrl']?['stringValue'],
        referralCode: fields['referralCode']?['stringValue'],
        referredBy: fields['referredBy']?['stringValue'],
        createdAt: fields['createdAt'] != null
          ? DateTime.tryParse(fields['createdAt']['timestampValue'] ?? '')
          : null,
      );
    } catch (e, stack) {
      print('❌ Error in UserModel.fromFirestore: $e');
      print('📍 Stack trace: $stack');
      print('🧪 Raw fields received: $fields');
      return UserModel(uid: '', email: '', fullName: '', country: '', state: '', city: '', createdAt: null);
    }
  }
  // PATCH END

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'fullName': fullName,
    'country': country,
    'state': state,
    'city': city,
    'photoUrl': photoUrl,
    'referralCode': referralCode,
    'referredBy': referredBy,
    'createdAt': createdAt?.toIso8601String(),
  };
}