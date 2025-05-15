// FINAL PATCHED — downline_team_screen.dart (null-safe handling for DateTime on ListTile display)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../services/session_manager.dart';
import 'profile_screen.dart';

class DownlineTeamScreen extends StatefulWidget {
  const DownlineTeamScreen({super.key});

  @override
  State<DownlineTeamScreen> createState() => _DownlineTeamScreenState();
}

// PATCH START: Fix state class name mismatch
class _DownlineTeamScreenState extends State<DownlineTeamScreen> {
// PATCH END
  bool isLoading = false;
  List<UserModel> allDownlineUsers = [];
  Map<int, List<UserModel>> groupedDownline = {};

  final session = SessionManager.instance;
  List<UserModel> fullTeam = [];
  List<UserModel> visibleTeam = [];
  Map<int, int> levelCounts = {};
  int selectedLevel = -1;
  String selectedFilter = 'All';
  final filters = ['All', 'Last 7 Days', 'Last 30 Days'];

  @override
  void initState() {
    super.initState();
    fetchDownlineFromFunction();
  }

  Future<void> fetchDownlineFromFunction() async {
    setState(() => isLoading = true);
    try {
      final email = SessionManager.instance.currentUser?.email;
      if (email == null || email.trim().isEmpty) {
        throw Exception('User email not available');
      }

      final url = Uri.parse('https://us-central1-teambuilder-plus-fe74d.cloudfunctions.net/getDownlineUsers');
      final response = await http.get(
        url,
        headers: {'x-user-email': email},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch downline data');
      }

      final List<dynamic> raw = json.decode(response.body);

      // PATCH START: restored docId param to rehydrate UID
      allDownlineUsers = raw.map((j) => UserModel.fromFirestore(
        j['fields'],
        docId: j['name'].split('/').last,
      )).toList();
      // PATCH END

      fullTeam = List.from(allDownlineUsers);
      _applyFilters();
    } catch (e) {
      print('❌ Error fetching downline: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  int? extractLevel(UserModel user) {
    try {
      final raw = user.toJson();
      final rawLevel = raw['level'];
      if (rawLevel is int) return rawLevel;
      if (rawLevel is String) return int.tryParse(rawLevel);
    } catch (_) {}
    return null;
  }

  void _applyFilters() {
    final now = DateTime.now();
    List<UserModel> filtered = List.from(fullTeam);

    if (selectedFilter == 'Last 7 Days') {
      filtered = filtered.where((u) => u.createdAt != null && u.createdAt!.isAfter(now.subtract(Duration(days: 7)))).toList();
    } else if (selectedFilter == 'Last 30 Days') {
      filtered = filtered.where((u) => u.createdAt != null && u.createdAt!.isAfter(now.subtract(Duration(days: 30)))).toList();
    }

    if (selectedLevel >= 0) {
      filtered = filtered.where((u) => extractLevel(u) == selectedLevel).toList();
    }

    levelCounts = {};
    for (var u in fullTeam) {
      final lvl = extractLevel(u) ?? -1;
      levelCounts[lvl] = (levelCounts[lvl] ?? 0) + 1;
    }

    setState(() {
      visibleTeam = filtered;
    });
  }

  Widget _buildFilterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: filters.map((f) => _buildFilterButton(f)).toList(),
    );
  }

  Widget _buildFilterButton(String label) {
    final isSelected = label == selectedFilter;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          selectedFilter = label;
          _applyFilters();
        });
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: isSelected ? Colors.indigo : Colors.grey),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.indigo : Colors.black)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downline Team')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: _buildFilterRow(),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: visibleTeam.length,
                    itemBuilder: (context, index) {
                      final u = visibleTeam[index];
                      final dt = u.createdAt;
                      final level = extractLevel(u);
                      final joinedText = dt != null ? 'Joined ${dt.month}/${dt.day}/${dt.year}' : 'Join date unknown';
                      return ListTile(
                        title: Text(u.fullName ?? 'Unnamed'),
                        subtitle: Text('${u.email}\n$joinedText'),
                        isThreeLine: true,
                        trailing: Text('L${level ?? '-'}'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen()),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
