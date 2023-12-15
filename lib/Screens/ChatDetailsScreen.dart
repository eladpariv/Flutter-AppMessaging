import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_app/services/ChatService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDetailsScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailsScreen({required this.chatId});

  @override
  _ChatDetailsScreenState createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();

  Map<String, dynamic>? chatData;

  @override
  void initState() {
    super.initState();
    updateAndSaveDocument();
  }

  Future<void> updateAndSaveDocument() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      Map<String, dynamic> chatDocData =
          documentSnapshot.data() as Map<String, dynamic>;

      setState(() {
        chatData = chatDocData;
      });
    } catch (e) {
      print('Error updating and saving document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return chatData != null
        ? Scaffold(
            appBar: AppBar(
              title: Text('${chatData!['name']}'),
            ),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      var messages = snapshot.data!['messages'] ?? [];

                      return ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          var message = messages[index];
                          var senderId = message['senderId'] as String;
                          var text = message['text'] as String;
                          return MessageRep(senderId: senderId, text: text);
                        },
                      );
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
          )
        : Scaffold();
  }

  Widget _buildMessageInput() {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 10.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(15.0), // Adjust the value as needed
                color: const Color.fromARGB(
                    255, 197, 195, 195), // Background color for the ellipse
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  border: InputBorder.none, // Remove bottom black line
                  hintText: 'Type a message...',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 1),
                ),
              ),
            ),
          ),
          const SizedBox(
              width:
                  5.0), // Add some spacing between the text field and the icon
          Container(
            width: 35,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromARGB(
                  255, 52, 158, 245), // Background color for the icon ellipse
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              iconSize: 15,
              onPressed: () {
                String? currentUserId = FirebaseAuth.instance.currentUser!.uid;
                String messageText = _messageController.text.trim();
                _sendMessage(currentUserId, messageText, widget.chatId);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(currentUserId, messageText, chatId) {
    if (messageText.isNotEmpty) {
      FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'messages': FieldValue.arrayUnion([
          {
            'senderId': currentUserId,
            'text': messageText,
          }
        ]),
      });
      _messageController.clear();
    }
  }
}

class MessageRep extends StatefulWidget {
  final String senderId;
  final String text;

  const MessageRep({super.key, required this.senderId, required this.text});
  @override
  _MessageRep createState() => _MessageRep();
}

class _MessageRep extends State<MessageRep> {
  Map<String, dynamic> senderData = {};

  @override
  void initState() {
    super.initState();
    updateAndSaveDocument();
  }

  Future<void> updateAndSaveDocument() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.senderId)
          .get();

      Map<String, dynamic> senderDocData =
          documentSnapshot.data() as Map<String, dynamic>;

      setState(() {
        senderData = senderDocData;
      });
    } catch (e) {
      print('Error updating and saving document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          vertical: 5.0, horizontal: 10.0), // Adjust margins as needed

      decoration: BoxDecoration(
        color: Colors.grey[200], // Background color
        borderRadius: BorderRadius.circular(19.0), // Elliptical shape
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            vertical: 0.0,
            horizontal: 15.0), // Optional: Padding around the ListTile
        leading: senderData != null && senderData?['imageUri'] != null
            ? CircleAvatar(
                radius: 15,
                backgroundImage: NetworkImage(senderData?['imageUri']),
              )
            : null,
        title: Text(
          '${senderData!['name']}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${widget.text}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
