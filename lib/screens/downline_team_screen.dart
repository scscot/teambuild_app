// CLEAN PATCHED — downline_team_screen.dart with placeholder spacing logic

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/session_manager.dart';
import '../screens/member_detail_screen.dart';
import '../widgets/header_widgets.dart';

enum JoinWindow {
  all,
  last24,
  last7,
  last30,
}

class DownlineTeamScreen extends StatefulWidget {
  final String referredBy;
  const DownlineTeamScreen({super.key, required this.referredBy});

  @override
  State<DownlineTeamScreen> createState() => _DownlineTeamScreenState();
}

class _DownlineTeamScreenState extends State<DownlineTeamScreen> {
  bool isLoading = true;
  JoinWindow selectedJoinWindow = JoinWindow.all;
  Map<int, List<UserModel>> downlineByLevel = {};
  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  int levelOffset = 0;

  @override
  void initState() {
    super.initState();
    fetchDownline();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool userMatchesSearch(UserModel user) {
    final query = _searchQuery.toLowerCase();
    return [
      user.firstName,
      user.lastName,
      user.city,
      user.state,
      user.country
    ].any((field) => field != null && field.toLowerCase().contains(query));
  }

  Future<void> fetchDownline() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final allUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          uid: doc.id,
          email: data['email'] ?? '',
          firstName: data['firstName'],
          lastName: data['lastName'],
          country: data['country'],
          state: data['state'],
          city: data['city'],
          referredBy: data['referredBy'],
          referralCode: data['referralCode'],
          photoUrl: data['photoUrl'],
          joined: _parseTimestamp(data['createdAt']),
          createdAt: _parseTimestamp(data['createdAt']),
          level: data['level'],
        );
      }).toList();

      final currentUserModel = allUsers.firstWhere(
        (u) => u.uid == currentUser?.uid,
        orElse: () => UserModel(uid: '', email: ''),
      );

      final currentRefCode = currentUserModel.referralCode;

      if (currentRefCode == null || currentRefCode.isEmpty) {
        debugPrint('⚠️ Current user referralCode is null or empty');
        setState(() => isLoading = false);
        return;
      }

      levelOffset = currentUserModel.level != null ? currentUserModel.level! : 0;

      final Set<String> visited = {};
      final Map<int, List<UserModel>> grouped = {};

      void collectDownline(String refCode) {
        final direct = allUsers.where((u) => u.referredBy == refCode).toList();
        final now = DateTime.now();

        Duration? filterDuration;
        if (_searchQuery.isEmpty) {
          switch (selectedJoinWindow) {
            case JoinWindow.last24:
              filterDuration = const Duration(hours: 24);
              break;
            case JoinWindow.last7:
              filterDuration = const Duration(days: 7);
              break;
            case JoinWindow.last30:
              filterDuration = const Duration(days: 30);
              break;
            case JoinWindow.all:
            default:
              filterDuration = null;
          }
        }

        for (var user in direct) {
          if (user.level != null) {
            final joined = user.joined;
            if (filterDuration != null && joined != null) {
              final cutoff = now.subtract(filterDuration);
              if (joined.isBefore(cutoff)) continue;
            }

            if (!visited.contains(user.referralCode)) {
              visited.add(user.referralCode ?? '');
              collectDownline(user.referralCode ?? '');
            }

            if (_searchQuery.isNotEmpty && !userMatchesSearch(user)) continue;

            grouped.putIfAbsent(user.level!, () => []).add(user);
          }
        }
      }

      collectDownline(currentRefCode);

      grouped.forEach((level, users) {
        users.sort((a, b) => b.joined?.compareTo(a.joined ?? DateTime(1970)) ?? 0);
      });

      setState(() {
        downlineByLevel = Map.fromEntries(grouped.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)));
      });
    } catch (e) {
      debugPrint('Error loading downline: $e');
    }
    setState(() => isLoading = false);
  }

  String _dropdownLabel(JoinWindow window) {
    switch (window) {
      case JoinWindow.last24:
        return 'Joined Previous 24 Hours';
      case JoinWindow.last7:
        return 'Joined Previous 7 Days';
      case JoinWindow.last30:
        return 'Joined Previous 30 Days';
      case JoinWindow.all:
      default:
        return 'My Downline Team';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeaderWithMenu(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 24.0),
                  child: Center(
                    child: Text(
                      'Downline Team',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search downline...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      if (value.trim().isEmpty) fetchDownline();
                    },
                    onSubmitted: (value) {
                      setState(() => _searchQuery = value);
                      fetchDownline();
                    },
                  ),
                ),
                if (_searchQuery.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                    child: DropdownButton<JoinWindow>(
                      isExpanded: true,
                      value: selectedJoinWindow,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedJoinWindow = value);
                          fetchDownline();
                        }
                      },
                      items: JoinWindow.values.map((window) {
                        return DropdownMenuItem(
                          value: window,
                          child: Text(
                            _dropdownLabel(window),
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    children: [
                      ...downlineByLevel.entries.map((entry) {
                        final adjustedLevel = entry.key - levelOffset;
                        final users = entry.value;
                        int localIndex = 1;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(thickness: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                              child: Text(
                                'Level $adjustedLevel (${users.length})',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ),
                            ...users.map((user) {
                              final index = localIndex++;
                              final spaceCount = index < 10 ? 4 : index < 100 ? 6 : 7;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '$index) ',
                                          style: const TextStyle(fontWeight: FontWeight.normal),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => MemberDetailScreen(userId: user.uid),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            '${user.firstName ?? ''} ${user.lastName ?? ''}',
                                            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${' ' * spaceCount}${user.city ?? ''}, ${user.state ?? ''} – ${user.country ?? ''}',
                                      style: const TextStyle(fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              );
                            })
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} // PATCH END
