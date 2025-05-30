import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/header_widgets.dart';
import '../services/session_manager.dart';
import '../services/firestore_service.dart';

class MessageCenterScreen extends StatefulWidget {
  const MessageCenterScreen({super.key});

  @override
  State<MessageCenterScreen> createState() => _MessageCenterScreenState();
}

class _MessageCenterScreenState extends State<MessageCenterScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _errorText;
  final currentUser = SessionManager.instance;
  final FirestoreService _firestoreService = FirestoreService();

  final urlPattern = RegExp(
    r'(?:(?:https?:\/\/|www\.)[^\s/$.?#].[^\s]*)|(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+(?:[a-zA-Z]{2,63})(?:\/[^\s]*)?',
    caseSensitive: false,
  );

  final emailPattern = RegExp(
    r'(?:\b[A-Z0-9._%+-]+(?:\s*\[at\]\s*|\s*\(at\)\s*)[A-Z0-9.-]+(?:\s*\[dot\]\s*|\s*\(dot\)\s*|\.)[A-Z]{2,6}\b)|(?:\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,6}\b)',
    caseSensitive: false,
  );

  final phonePattern = RegExp(
    r'(?:\+?(\d{1,3}))?[-. (]*(\d{3})[-. )]*(\d{3})[-. ]*(\d{4})(?:\s*(?:ext|x|extension)\s*(\d+))?',
    caseSensitive: false,
  );

  bool _containsProhibitedContent(String message) {
    final lower = message.toLowerCase();
    return urlPattern.hasMatch(lower) ||
        emailPattern.hasMatch(lower) ||
        phonePattern.hasMatch(lower);
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (_containsProhibitedContent(message)) {
      setState(() {
        _errorText = '❌ Links, emails, and phone numbers are not allowed.';
      });
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Invalid Content'),
          content: const Text(
              'Messages cannot contain website links, email addresses, or phone numbers.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final user = await currentUser.getCurrentUser();
    if (user == null || !mounted) return;

    try {
      await _firestoreService.sendMessage(
        senderId: user.uid,
        recipientId: 'mockRecipientId', // Replace with actual recipient logic
        text: message,
      );

      setState(() {
        _errorText = null;
        _messageController.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Message sent')),
      );

      // Auto-scroll to bottom
      Future.delayed(Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('❌ Failed to send message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to send message')),
      );
    }
  }

  String _generateThreadId(String id1, String id2) {
    final sorted = [id1, id2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<QuerySnapshot> _getMessagesStream(String threadId) {
    return FirebaseFirestore.instance
        .collection('messages')
        .doc(threadId)
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeaderWithMenu(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Padding(
            padding: EdgeInsets.only(top: 24.0),
            child: Center(
              child: Text(
                'Message Center',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMessagesStream(
                  _generateThreadId('mockUser', 'mockRecipientId')),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('📨 No messages yet.',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['text'] ?? ''),
                      subtitle:
                          Text(data['timestamp']?.toDate().toString() ?? ''),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendMessage,
                child: const Text('Send Message'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
