import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getChats() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await _firestore.collection('chats').get();

      List<String> chatIds = querySnapshot.docs.map((doc) => doc.id).toList();

      return chatIds;
    } catch (e) {
      return [];
    }
  }
}
