import 'package:flutter/material.dart';
import 'package:my_flutter_app/Screens/AddNewGroupScreen.dart';
import 'package:my_flutter_app/Screens/ChatDetailsScreen.dart';
import 'package:my_flutter_app/Screens/Group/GroupChatScreen.dart';
import 'package:my_flutter_app/services/ChatService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_app/services/GroupsService.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);
  static const route = './NotificationScreen';

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ChatService _chatService = ChatService();
  final GroupsService _groupsService = GroupsService();

  List<String> chats = [];
  List<String> groups = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
    _loadGroups();
  }

  Future<void> _loadChats() async {
    List<String> updatedChats = await _chatService.getChats();
    setState(() {
      chats = updatedChats;
    });
  }

  Future<void> _loadGroups() async {
    List<String> updatedGroups = await _groupsService.getGroups();
    setState(() {
      groups = updatedGroups;
    });
  }

  void _openAddToGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return AddToGroupModal(
          loadChats: _loadChats,
          loadGroups: _loadGroups,
        );
      },
    );
  }

  void _navigateToChatDetails(String chatId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailsScreen(chatId: chatId),
      ),
    );
  }

  void _navigateToGroupDetails(String groupId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return GroupChatScreen(groupId: groupId);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.fastEaseInToSlowEaseOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _openAddToGroupModal(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Groups'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Chats Tab
            ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _navigateToChatDetails(chats[index]);
                  },
                  child: ListTile(
                    title: Text('${chats[index]}'),
                  ),
                );
              },
            ),
            // Groups Tab
            ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _navigateToGroupDetails(groups[index]);
                      },
                      child: RepTabGroup(groupId: groups[index]),
                    ),
                    const Divider(
                      indent: 20,
                      endIndent: 20,
                      color: Colors.grey, // Adjust the color as needed
                      thickness: 0.5, // Adjust the thickness as needed
                      height:
                          0, // The height property can be used to control the spacing
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RepTabGroup extends StatefulWidget {
  final String groupId;

  const RepTabGroup({required this.groupId});

  @override
  _RepTabGroup createState() => _RepTabGroup();
}

class _RepTabGroup extends State<RepTabGroup> {
  Map<String, dynamic>? lastMessage;
  Map<String, dynamic>? senderData;
  String? formattedTimeLastMessage;

  Future<void> updateAndSaveDocument() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      Map<String, dynamic> groupDocData =
          documentSnapshot.data() as Map<String, dynamic>;

      // Fetch the last message reference from the group
      List<dynamic> messages = groupDocData['messages'] ?? [];
      if (messages.isNotEmpty) {
        // Get the last message reference
        DocumentReference lastMessageRef = messages.last;

        // Fetch the last message data
        DocumentSnapshot lastMessageSnapshot = await lastMessageRef.get();
        Map<String, dynamic> lastMessageData =
            lastMessageSnapshot.data() as Map<String, dynamic>;

        // Fetch the sender data
        String senderId = lastMessageData['senderId'];
        DocumentSnapshot senderSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .get();
        Map<String, dynamic> senderDocData =
            senderSnapshot.data() as Map<String, dynamic>;

        // DateTime dateTime = lastMessageData?['timestamp'].toDate();
        // String formattedTime =
        //     '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

        setState(() {
          // formattedTimeLastMessage = formattedTime;
          // groupData = groupDocData;
          lastMessage = lastMessageData;
          senderData = senderDocData;
        });
      } else {
        setState(() {
          // groupData = groupDocData;
          lastMessage = null;
          senderData = null;
        });
      }
    } catch (e) {
      print('Error updating and saving document: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    updateAndSaveDocument();
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
          return Text('Document does not exist');
        }

        Map<String, dynamic>? groupData =
            snapshot.data?.data() as Map<String, dynamic>;

        updateAndSaveDocument();
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          leading: SizedBox(
            width: 50,
            height: 50,
            child: groupData?['imageUri'] != null
                ? Container(
                    width: 40,
                    height: 40,
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
          title: Text(
            '${groupData?['name']}',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: lastMessage != null
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (senderData != null)
                      Text(
                        '${senderData?['name']}',
                        style: TextStyle(fontSize: 13),
                      ),
                    const SizedBox(
                      width: 3,
                      height: 3,
                    ),
                    const Icon(
                      Icons.circle_sharp,
                      color: Colors.grey,
                      size: 5,
                    ),
                    const SizedBox(
                      width: 3,
                      height: 3,
                    ),
                    Text(
                      '${lastMessage?['text']}',
                      style: TextStyle(fontSize: 13),
                    )
                  ],
                )
              : Text(''),
        );
      },
    );
  }
}
