import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/header_widgets.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class MemberDetailScreen extends StatefulWidget {
  final String userId;

  const MemberDetailScreen({super.key, required this.userId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  UserModel? _user;
  String? _sponsorName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await FirestoreService().getUser(widget.userId);
      if (user != null) {
        setState(() => _user = user);

        if (user.referredBy != null && user.referredBy!.isNotEmpty) {
          final sponsorName = await FirestoreService().getSponsorNameByReferralCode(user.referredBy!);
          if (mounted) setState(() => _sponsorName = sponsorName);
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to load member: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeaderWithBack(),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _user!.photoUrl != null && _user!.photoUrl!.isNotEmpty
                          ? NetworkImage(_user!.photoUrl!)
                          : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Name', '${_user!.firstName} ${_user!.lastName}'),
                  _buildInfoRow('City', _user!.city ?? 'N/A'),
                  _buildInfoRow('State/Province', _user!.state ?? 'N/A'),
                  _buildInfoRow('Country', _user!.country ?? 'N/A'),
                  _buildInfoRow(
                    'Join Date',
                    _user!.createdAt != null ? DateFormat.yMMMMd().format(_user!.createdAt!) : 'N/A',
                  ),
                  if (_sponsorName != null && _sponsorName!.isNotEmpty)
                    _buildInfoRow('Sponsor Name', _sponsorName!),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: implement messaging action
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Send Message'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
