// PATCHED — Fully restored from REST-based downline_team_screen.dart with SDK-based Firestore logic

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class DownlineTeamScreen extends StatefulWidget {
  final String referredByUid;

  const DownlineTeamScreen({super.key, required this.referredByUid});

  @override
  State<DownlineTeamScreen> createState() => _DownlineTeamScreenState();
}

class _DownlineTeamScreenState extends State<DownlineTeamScreen> {
  late Future<List<UserModel>> _downlineUsersFuture;

  @override
  void initState() {
    super.initState();
    _downlineUsersFuture = FirestoreService().getDownlineUsers(widget.referredByUid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Downline Team'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _downlineUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading team: \${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No downline team members found.'));
          } else {
            final users = snapshot.data!;
            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text('\${user.firstName} \${user.lastName}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: \${user.email}'),
                      if (user.createdAt != null)
                        Text('Joined: \${user.createdAt!.toDate().toLocal().toString().split(".")[0]}'),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
