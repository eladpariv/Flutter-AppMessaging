import 'package:cloud_firestore/cloud_firestore.dart';

class GroupsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getGroups() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await _firestore.collection('groups').get();

      List<String> groupsIds = querySnapshot.docs.map((doc) => doc.id).toList();

      return groupsIds;
    } catch (e) {
      return [];
    }
  }
}
