// PATCHED — downline_team_screen.dart with required referredByUid constructor param

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class DownlineTeamScreen extends StatefulWidget {
  final String referredByUid;
  const DownlineTeamScreen({super.key, required this.referredByUid});

  @override
  State<DownlineTeamScreen> createState() => _DownlineTeamScreenState();
}

class _DownlineTeamScreenState extends State<DownlineTeamScreen> {
  List<UserModel> _downlineUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDownlineUsers();
  }

  Future<void> _fetchDownlineUsers() async {
    try {
      final users = await FirestoreService().getDownlineUsers(widget.referredByUid);
      setState(() {
        _downlineUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching downline users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Downline'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downlineUsers.isEmpty
              ? const Center(child: Text('No downline members found.'))
              : ListView.builder(
                  itemCount: _downlineUsers.length,
                  itemBuilder: (context, index) {
                    final user = _downlineUsers[index];
                    return ListTile(
                      title: Text('${user.firstName} ${user.lastName}'),
                      subtitle: user.createdAt != null
                          ? Text('Joined: ${user.createdAt!.toLocal().toString().split(" ")[0]}')
                          : const Text('Join date not available'),
                    );
                  },
                ),
    );
  }
}
