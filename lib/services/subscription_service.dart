import 'package:cloud_functions/cloud_functions.dart';

class SubscriptionService {
  static final HttpsCallable _checkStatus =
      FirebaseFunctions.instance.httpsCallable('checkAdminSubscriptionStatus');

  /// Returns `{ isActive: bool, daysRemaining: int, trialExpired: bool }`
  static Future<Map<String, dynamic>> checkAdminSubscriptionStatus(
      String uid) async {
    try {
      final result = await _checkStatus.call({'uid': uid});
      final data = Map<String, dynamic>.from(result.data);
      return data;
    } catch (e) {
      print('❌ Error checking subscription status: $e');
      return {
        'isActive': false,
        'daysRemaining': 0,
        'trialExpired': true,
      };
    }
  }
}
