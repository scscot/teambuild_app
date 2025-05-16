import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/session_manager.dart';
import 'package:intl/intl.dart';

class DownlineTeamScreen extends StatefulWidget {
  const DownlineTeamScreen({super.key});

  @override
  State<DownlineTeamScreen> createState() => _DownlineTeamScreenState();
}

class _DownlineTeamScreenState extends State<DownlineTeamScreen> {
  List<UserModel> _downlineUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownlineUsers();
  }

  Future<void> _loadDownlineUsers() async {
    final currentUser = SessionManager().currentUser;
    if (currentUser == null) return;

    final referredByUid = currentUser.uid;
    final users = await FirestoreService().getDownlineUsers(referredByUid);
    setState(() {
      _downlineUsers = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Downline'),
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downlineUsers.isEmpty
              ? const Center(child: Text('No team members found.'))
              : ListView.builder(
                  itemCount: _downlineUsers.length,
                  itemBuilder: (context, index) {
                    final user = _downlineUsers[index];
                    final fullName = '${user.firstName} ${user.lastName}';
                    final joinDate = user.createdAt != null
                        ? DateFormat.yMMMMd().format(user.createdAt!)
                        : 'N/A';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(fullName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            Text('Joined: $joinDate'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
