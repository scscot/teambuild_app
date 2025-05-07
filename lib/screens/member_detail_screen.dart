import 'package:flutter/material.dart';

class MemberDetailScreen extends StatelessWidget {
  final Map<String, dynamic> member;

  const MemberDetailScreen({required this.member});

  @override
  Widget build(BuildContext context) {
    final joinDate = member['joinDate'] as DateTime;
    final formattedDate = '${joinDate.month}/${joinDate.day}/${joinDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(member['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${member['name']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Location: ${member['city']}, ${member['state']}, ${member['country']}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Join Date: $formattedDate', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Level: ${member['level']}', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
