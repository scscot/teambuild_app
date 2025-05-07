// FINAL PATCHED — downline_team_screen.dart (routes Firestore access through getDownlineUsers Cloud Function)

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

class _DownlineTeamScreenState extends State<DownlineTeamScreen> {
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
      allDownlineUsers = raw.map((j) => UserModel.fromJson(j)).toList();
      fullTeam = List.from(allDownlineUsers);
      _applyFilters();
    } catch (e) {
      print('❌ Error fetching downline: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    final now = DateTime.now();
    List<UserModel> filtered = List.from(fullTeam);

    if (selectedFilter == 'Last 7 Days') {
      filtered = filtered.where((u) => u.createdAt.isAfter(now.subtract(Duration(days: 7)))).toList();
    } else if (selectedFilter == 'Last 30 Days') {
      filtered = filtered.where((u) => u.createdAt.isAfter(now.subtract(Duration(days: 30)))).toList();
    }

    if (selectedLevel >= 0) {
      filtered = filtered.where((u) => u.level == '$selectedLevel').toList();
    }

    levelCounts = {};
    for (var u in fullTeam) {
      final lvl = int.tryParse(u.level ?? '-1') ?? -1;
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
                      return ListTile(
                        title: Text(u.fullName),
                        subtitle: Text('${u.email}\nJoined ${dt.month}/${dt.day}/${dt.year}'),
                        isThreeLine: true,
                        trailing: Text('L${u.level ?? '-'}'),
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
