import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/header_widgets.dart';
import 'join_opportunity_confirmation_screen.dart';

class JoinOpportunityScreen extends StatefulWidget {
  const JoinOpportunityScreen({super.key});

  @override
  State<JoinOpportunityScreen> createState() => _JoinOpportunityScreenState();
}

class _JoinOpportunityScreenState extends State<JoinOpportunityScreen> {
  String? firstName;
  String? bizOpp;
  String? bizOppRefUrl;
  String? sponsorName;
  int directSponsorMin = 0;
  int totalTeamMin = 0;
  int currentDirect = 0;
  int currentTeam = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadOpportunityData();
  }

  Future<void> _loadOpportunityData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data();
    if (userData == null) return;

    setState(() {
      firstName = userData['firstName'];
      currentDirect = userData['direct_sponsor_count'] ?? 0;
      currentTeam = userData['total_team_count'] ?? 0;
    });

    // Traverse up upline to find first sponsor with biz_opp_ref_url
    String? currentUid = userData['referredBy'];
    while (currentUid != null) {
      final refDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
      final refData = refDoc.data();
      if (refData != null) {
        if (refData['biz_opp_ref_url'] != null) {
          setState(() {
            bizOppRefUrl = refData['biz_opp_ref_url'];
            sponsorName = '${refData['firstName']} ${refData['lastName']}';
            bizOpp = refData['biz_opp'];
            directSponsorMin = refData['direct_sponsor_min'] ?? 0;
            totalTeamMin = refData['total_team_min'] ?? 0;
          });
          break;
        }
        currentUid = refData['referredBy'];
      } else {
        break;
      }
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        appBar: AppHeaderWithMenu(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const AppHeaderWithMenu(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations, $firstName!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              "Your TeamBuild Pro downline is growing, and you've hit an exciting milestone: you've personally sponsored $directSponsorMin members and have a total of $totalTeamMin downline members!\n\nThis means you're now eligible to join the $bizOpp opportunity!\n\nSimply click the button below to complete your $bizOpp registration. Once you're done, come back to the TeamBuild Pro app and update your profile with your new $bizOpp referral link. That way, any of your downline who join $bizOpp after you will automatically be placed in your $bizOpp downline."
            ),
            const SizedBox(height: 24),
            Text(
              'Join Opportunity',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: bizOppRefUrl != null
                  ? () => launchUrl(Uri.parse(bizOppRefUrl!))
                  : null,
              child: Text('Join $bizOpp Now!'),
            ),
            const SizedBox(height: 16),
            Text(
              "Your ‘$bizOpp’ sponsor is $sponsorName — the first person in your TeamBuild Pro upline who has completed ‘$bizOpp’ registration. This may differ from your TeamBuild Pro sponsor if they haven't yet registered for ‘$bizOpp’.",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JoinOpportunityConfirmationScreen(),
                    ),
                  );
                },
                child: const Text('Update My Profile Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
