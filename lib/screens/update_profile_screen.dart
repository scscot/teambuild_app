import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/header_widgets.dart';
import 'my_biz_screen.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _refLinkController = TextEditingController();
  String? baseUrl;
  String? bizOpp;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final adminSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();

    if (adminSnapshot.docs.isNotEmpty) {
      final adminData = adminSnapshot.docs.first.data();
      final fullUrl = adminData['biz_opp_ref_url'];
      if (fullUrl != null && fullUrl is String) {
        final uri = Uri.tryParse(fullUrl);
        if (uri != null) {
          setState(() {
            baseUrl =
                '${uri.scheme}://${uri.host}${uri.path.endsWith('/') ? uri.path : uri.path + '/'}';
            bizOpp = adminData['biz_opp'];
          });
        }
      }
    }
  }

  Future<void> _submitReferral() async {
    if (!_formKey.currentState!.validate() || baseUrl == null) return;
    final userInput = _refLinkController.text.trim();

    if (!userInput.startsWith(baseUrl!)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Invalid Referral Link'),
          content: Text('Your unique referral link must begin with $baseUrl.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK!'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'biz_opp_ref_url': userInput,
      'biz_join_date': FieldValue.serverTimestamp(),
      'biz_opp': bizOpp,
    });

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyBizScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeaderWithMenu(),
      body: baseUrl == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "Congratulations on completing your '$bizOpp' registration.",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Updating your TeamBuild Pro profile with your unique '$bizOpp' referral link ensures that anyone in your TeamBuild Pro downline who completes their '$bizOpp' registration will automatically be placed in your '$bizOpp' downline.",
                    ),
                    const SizedBox(height: 24),
                    Text(
                      bizOpp ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _refLinkController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Your Unique Referral Link',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _submitReferral,
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Update My Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
