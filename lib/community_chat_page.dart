import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_cm.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class CommunityChatPage extends StatefulWidget {
  final String communityId;
  final String communityName;
  final String userName;

  const CommunityChatPage({
    Key? key,
    required this.communityId,
    required this.communityName,
    required this.userName,
  }) : super(key: key);

  @override
  _CommunityChatPageState createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  var communityName;
  
  

  /// Sends a message and notifies community members
  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String messageText = _messageController.text;
      String senderName = widget.userName;
      String senderId = _auth.currentUser?.uid ?? "Anonymous";

      // ✅ Store message in Firestore
      await _firestore
          .collection("communities")
          .doc(widget.communityId)
          .collection("messages")
          .add({
        'message': messageText,
        'sender': senderName,
        'userId': senderId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();

      // ✅ Send notifications to community members
      await sendNotificationToCommunityUsers(senderId, messageText);
    }
  }
  Future<void> sendNotificationToCommunityUsers(String senderId, String message) async {
    QuerySnapshot membersSnapshot = await _firestore
        .collection("communities")
        .doc(widget.communityId)
        .collection("members")
        .get();

    List<String> fcmTokens = [];

    // Fetch sender's name
    var senderSnapshot = await _firestore.collection("users").doc(senderId).get();
    String senderName = senderSnapshot.exists ? (senderSnapshot.data()?["name"] ?? "Unknown") : "Unknown";

    for (var doc in membersSnapshot.docs) {
      String userId = doc.id;
      if (userId != senderId) { // ✅ Exclude sender
        var userSnapshot = await _firestore.collection("users").doc(userId).get();
        if (userSnapshot.exists && userSnapshot.data()?["fcmToken"] != null) {
          fcmTokens.add(userSnapshot.data()!["fcmToken"]);
        }
      }
    }

    if (fcmTokens.isNotEmpty) {
      for (String token in fcmTokens) {
        // Send notification with sender's name
        await FirebaseCM.sendTokenNotification(token, "Message from $senderName", message, senderName);
      }
    } else {
      print("❌ No FCM tokens found for notification.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.communityName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("communities")
                  .doc(widget.communityId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData = messages[index].data() as Map<String, dynamic>;
                    bool isMe = messageData['userId'] == _auth.currentUser?.uid;
                    return _buildMessageBubble(messageData, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe) {
    String formattedTime = _formatTimestamp(messageData['timestamp']);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: isMe ? const Radius.circular(10) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              messageData['sender'] ?? 'Unknown',
              style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 5),
            Text(
              messageData['message'] ?? '',
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                formattedTime,
                style: TextStyle(fontSize: 12, color: isMe ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Enter your message...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: sendMessage,
          ),
        ],
      ),
    );
  }
}
