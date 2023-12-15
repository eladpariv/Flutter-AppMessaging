import 'package:flutter/material.dart';
import 'package:my_flutter_app/Screens/ChatDetailsScreen.dart';
import 'package:my_flutter_app/Screens/Group/GroupChatScreen.dart';
import 'package:my_flutter_app/services/ChatService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_app/services/GroupsService.dart';

class AddToGroupModal extends StatefulWidget {
  final VoidCallback loadChats;
  final VoidCallback loadGroups;

  const AddToGroupModal({
    Key? key,
    required this.loadChats,
    required this.loadGroups,
  }) : super(key: key);

  @override
  _AddToGroupModalState createState() => _AddToGroupModalState();
}

class _AddToGroupModalState extends State<AddToGroupModal> {
  List<String> selectedUsers = [];
  List<String> users = [];
  TextEditingController groupNameController = TextEditingController();
  TextEditingController groupDescriptionController = TextEditingController();

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
    List<String> loadedUsers = await getUsers();
    setState(() {
      users = loadedUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'Add a new group',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          // Group Name TextField
          TextField(
            maxLength: 20,
            maxLines: 1,
            controller: groupNameController,
            decoration: const InputDecoration(
                labelText: 'Group Name',
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                )),
          ),
          const SizedBox(height: 10),
          // Group Description TextField
          TextField(
            maxLength: 70,
            maxLines: 2,
            controller: groupDescriptionController,
            decoration: const InputDecoration(
                labelText: 'Group Description',
                labelStyle: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 30),
          const Text(
            'Group members',
            style: TextStyle(fontSize: 16.0),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: users.map((userId) {
                  return UserRep(
                    userId: userId,
                    onUserSelected: (isSelected) {
                      setState(() {
                        if (isSelected) {
                          selectedUsers.add(userId);
                        } else {
                          selectedUsers.remove(userId);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _createGroup(selectedUsers),
            child: Text('Create Group'),
          ),
        ],
      ),
    );
  }

  void _createGroup(List<String> selectedUsers) async {
    String groupName = groupNameController.text;
    String groupDescription = groupDescriptionController.text;
    List<String> userIds = [...selectedUsers];

    await FirebaseFirestore.instance.collection('groups').add({
      'name': groupName,
      'description': groupDescription,
      'users': userIds,
      'messages': [],
      'imageUri': 'empty'
    });

    Navigator.pop(context);
    widget.loadGroups();
  }
}

class UserRep extends StatefulWidget {
  final String userId;
  final Function(bool isSelected) onUserSelected;

  const UserRep({Key? key, required this.userId, required this.onUserSelected})
      : super(key: key);

  @override
  _UserRepState createState() => _UserRepState();
}

class _UserRepState extends State<UserRep> {
  Map<String, dynamic> userData = {};
  bool isSelected = false;

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
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected = !isSelected;
          widget.onUserSelected(isSelected);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
            vertical: 5.0, horizontal: 10.0), // Adjust margins as needed

        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 67, 164, 244)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(19.0),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 3.0, horizontal: 15.0),
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
      ),
    );
  }
}
