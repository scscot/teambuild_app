// PATCHED — Auto-scroll on send, read receipts, SafeArea + message box padding

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/session_manager.dart';
import '../services/firestore_service.dart';
import '../widgets/header_widgets.dart';

class MessageThreadScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const MessageThreadScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _errorText;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final currentUser = await SessionManager().getCurrentUser();
    if (mounted) {
      setState(() => _currentUserId = currentUser?.uid);
      _markMessagesAsRead();
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

  Future<void> _markMessagesAsRead() async {
    final threadId = _generateThreadId(_currentUserId!, widget.recipientId);
    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(threadId)
        .collection('chat')
        .where('recipientId', isEqualTo: _currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    final containsProhibited =
        RegExp(r'(https?://|www\.|\.com|\w+@\w+|\+?\d[\d\s\-().]+)')
            .hasMatch(text);
    if (containsProhibited) {
      setState(() =>
          _errorText = 'Links, emails, and phone numbers are not allowed.');
      return;
    }

    await FirestoreService().sendMessage(
      senderId: _currentUserId!,
      recipientId: widget.recipientId,
      text: text,
    );

    setState(() {
      _errorText = null;
      _controller.clear();
    });

    // Auto-scroll to bottom
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final threadId = _generateThreadId(_currentUserId!, widget.recipientId);

    return Scaffold(
      appBar: const AppHeaderWithBack(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMessagesStream(threadId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _currentUserId;
                    final timestamp =
                        (data['timestamp'] as Timestamp?)?.toDate();
                    final read = data['isRead'] == true;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isMe ? Colors.blueAccent : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (timestamp != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      DateFormat.jm().format(timestamp),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                if (isMe && read)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Icon(Icons.done_all,
                                        size: 14, color: Colors.white70),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorText!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
