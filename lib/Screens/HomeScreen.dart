import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_app/services/ChatService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  static const route = './NotificationScreen';

  @override
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  final ChatService _chatService = ChatService();
  List<String> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<List<String>> getUsers() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      List<String> chatIds = querySnapshot.docs.map((doc) => doc.id).toList();

      return chatIds;
    } catch (e) {
      return [];
    }
  }

  Future<void> _loadUsers() async {
    List<String> updatedChats = await getUsers();
    setState(() {
      users = updatedChats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {},
            child: UserRep(userId: users[index]),
          );
        },
      ),
    );
  }
}

class UserRep extends StatefulWidget {
  final String userId;

  const UserRep({super.key, required this.userId});
  @override
  _UserRep createState() => _UserRep();
}

class _UserRep extends State<UserRep> {
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    updateAndSaveDocument();
  }

  Future<void> updateAndSaveDocument() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      Map<String, dynamic> senderDocData =
          documentSnapshot.data() as Map<String, dynamic>;

      setState(() {
        userData = senderDocData;
      });
    } catch (e) {
      print('Error updating and saving document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.grey[200], // Background color
        borderRadius: BorderRadius.circular(19.0), // Elliptical shape
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            vertical: 3.0,
            horizontal: 15.0), // Optional: Padding around the ListTile
        leading: userData != null && userData?['imageUri'] != null
            ? CircleAvatar(
                radius: 21,
                backgroundImage: NetworkImage(userData?['imageUri']),
              )
            : null,
        title: Text(
          '${userData!['name']}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
