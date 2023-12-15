import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_flutter_app/Components/MessageRep.dart';
import 'package:my_flutter_app/Screens/Group/GroupSettingScreen.dart';
import 'package:my_flutter_app/services/ChatService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<List<DocumentSnapshot>> fetchUsersDocs(List<dynamic> userIds) async {
  try {
    List<DocumentSnapshot> userDocuments = [];

    // Fetch user documents based on user IDs
    await Future.wait(userIds.map((userId) async {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      userDocuments.add(userSnapshot);
    }));

    return userDocuments;
  } catch (e) {
    print('Error fetching user documents: $e');
    return [];
  }
}

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({required this.groupId});

  @override
  _GroupChatScreen createState() => _GroupChatScreen();
}

class _GroupChatScreen extends State<GroupChatScreen> {
  bool _needsScroll = false;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  _scrollToEnd() async {
    if (_needsScroll) {
      _needsScroll = false;
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Text('Document does not exist');
            }

            Map<String, dynamic>? groupData =
                snapshot.data?.data() as Map<String, dynamic>;

            return ListTile(
                leading: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(groupData?['imageUri']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  '${groupData!['name']}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: FutureBuilder<List<DocumentSnapshot>>(
                  future: fetchUsersDocs(groupData?['users'] ?? []),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<DocumentSnapshot>> userSnapshot) {
                    if (userSnapshot.hasError) {
                      return Text(
                          'Error fetching user documents: ${userSnapshot.error}');
                    }
                    List<DocumentSnapshot> userDocuments =
                        userSnapshot.data ?? [];
                    List<dynamic> userNames = userDocuments
                        .map((user) => user['name'] ?? '')
                        .toList();

                    return Text(
                      '${userNames.join(', ')}',
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ));
          },
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.info),
              onPressed: _navigateToGroupInfoScreen),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: getMessagesStream(widget.groupId),
              builder: (context, snapshot) {
                List<DocumentSnapshot>? messages = snapshot.data;
                if (messages != null && messages.isNotEmpty) {
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      var senderId = message['senderId'] as String;
                      var text = message['text'] as String;
                      var serverTimestamp = message['timeStamp'] as Timestamp;

                      return MessageRep(
                          senderId: senderId,
                          text: text,
                          serverTimestamp: serverTimestamp,
                          message: message);
                    },
                  );
                } else {
                  return const Center();
                }
              },
            ),
          ),
          _buildMessageInput()
        ],
      ),
    );
  }

  Stream<List<DocumentSnapshot>> getMessagesStream(String groupId) {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .asyncMap<List<DocumentSnapshot>>((groupSnapshot) async {
      if (groupSnapshot.exists) {
        List<DocumentReference> messageReferences =
            List<DocumentReference>.from(groupSnapshot['messages']);

        List<DocumentSnapshot> messagesInOrder = [];

        await Future.wait(messageReferences.map((ref) => ref.get()))
            .then((listOfSnapshots) {
          messagesInOrder.addAll(listOfSnapshots);
        });

        return messagesInOrder;
      } else {
        return [];
      }
    });
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
                borderRadius: BorderRadius.circular(15.0),
                color: Color.fromARGB(255, 225, 224, 224),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  border: InputBorder.none, // Remove bottom black line
                  hintText: 'Type a message...',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5.0),
          Container(
            width: 35,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              iconSize: 20,
              onPressed: () {
                String? currentUserId = FirebaseAuth.instance.currentUser!.uid;
                String messageText = _messageController.text.trim();
                _sendMessage(currentUserId, messageText, widget.groupId);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(currentUserId, messageText, groupId) async {
    if (messageText.isNotEmpty) {
      CollectionReference messagesCollection =
          FirebaseFirestore.instance.collection('messages');

      DocumentReference newMessageRef = await messagesCollection.add({
        'senderId': currentUserId,
        'text': messageText,
        'timeStamp': FieldValue.serverTimestamp()
      });
      FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'messages': FieldValue.arrayUnion([newMessageRef])
      });
      _messageController.clear();
    }
  }

  void _navigateToGroupInfoScreen() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupInfoScreen(groupId: widget.groupId),
        ));
  }
}

class GroupInfoScreen extends StatefulWidget {
  final String groupId;

  const GroupInfoScreen({required this.groupId});

  @override
  _GroupInfoScreenState createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  File? _image;

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    try {
      if (FirebaseAuth.instance.currentUser != null && _image != null) {
        await FirebaseStorage.instance
            .ref()
            .child('groups_images/${widget.groupId}/profile_image.jpg')
            .putFile(_image!);

        String downloadURL = await FirebaseStorage.instance
            .ref()
            .child('groups_images/${widget.groupId}/profile_image.jpg')
            .getDownloadURL();

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
          'imageUri': downloadURL,
        });
      }
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Group details',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      groupId: widget.groupId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Text('Document does not exist');
            }

            Map<String, dynamic>? groupData =
                snapshot.data?.data() as Map<String, dynamic>;

            return SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: groupData?['imageUri'] != null
                            ? Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(groupData?['imageUri']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(),
                      ),
                      Positioned(
                        bottom: -10, // Adjust bottom margin as needed
                        right: -15, // Adjust right margin as needed
                        child: ElevatedButton(
                          onPressed: _getImage,
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                          ),
                          child: const SizedBox(
                            width: 15, // Adjust width as needed
                            height: 15, // Adjust height as needed
                            child: Icon(
                              Icons.camera_alt,
                              size: 15, // Adjust size as needed
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 5,
                    height: 5,
                  ),
                  Text(
                    '${groupData!['name']}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ColumnGroupUsers(groupId: widget.groupId)
                ],
              ),
            );
          },
        ));
  }
}

class ColumnGroupUsers extends StatefulWidget {
  final String groupId;

  const ColumnGroupUsers({required this.groupId});

  @override
  _ColumnGroupUsers createState() => _ColumnGroupUsers();
}

class _ColumnGroupUsers extends State<ColumnGroupUsers> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('Document does not exist');
        }

        Map<String, dynamic>? groupData =
            snapshot.data?.data() as Map<String, dynamic>;

        return FutureBuilder<List<DocumentSnapshot>>(
          future: fetchUsersDocs(groupData?['users'] ?? []),
          builder: (BuildContext context,
              AsyncSnapshot<List<DocumentSnapshot>> userSnapshot) {
            if (userSnapshot.hasError) {
              return Text(
                  'Error fetching user documents: ${userSnapshot.error}');
            }
            List<DocumentSnapshot> userDocuments = userSnapshot.data ?? [];

            if (userDocuments.isNotEmpty) {
              return Column(
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                  ),
                  Row(
                    children: [
                      Text(
                        '      ${userDocuments.length} Users',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Column(
                    children: userDocuments.map((user) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 0.0,
                          horizontal: 1.0,
                        ),
                        child: ListTile(
                          leading: user != null && user['imageUri'] != null
                              ? CircleAvatar(
                                  radius: 17,
                                  backgroundImage:
                                      NetworkImage(user['imageUri']),
                                )
                              : null,
                          title: Text(
                            '${user['name']}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            } else {
              return const Text(
                  'No members'); // Or any other placeholder for an empty list
            }
          },
        );
      },
    );
  }
}
