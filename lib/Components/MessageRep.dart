import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_flutter_app/services/ChatService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessageRep extends StatefulWidget {
  final String senderId;
  final String text;
  final Object message;
  final Timestamp serverTimestamp;

  const MessageRep({
    super.key,
    required this.senderId,
    required this.text,
    required this.message,
    required this.serverTimestamp,
  });

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

  @override
  void dispose() {
    super.dispose();
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
    DateTime dateTime = widget.serverTimestamp.toDate();
    String formattedTime =
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

    // Check if the sender's ID is equal to a specific ID
    bool isSpecificSender =
        widget.senderId == FirebaseAuth.instance.currentUser?.uid;

    return senderData != null && senderData['name'] != null
        ? ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0.0,
              horizontal: 10.0,
            ),
            leading: isSpecificSender
                ? null
                : (senderData != null && senderData?['imageUri'] != null
                    ? CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(senderData?['imageUri']),
                      )
                    : null),
            title: Container(
              child: Wrap(
                alignment:
                    isSpecificSender ? WrapAlignment.end : WrapAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    decoration: BoxDecoration(
                      color: isSpecificSender
                          ? const Color.fromARGB(255, 180, 195, 208)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child: Column(
                      children: [
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${senderData!['name']}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    width: 6,
                                    height: 6,
                                  ),
                                  const Icon(
                                    Icons.circle_sharp,
                                    color: Colors.grey,
                                    size: 10,
                                  ),
                                  const SizedBox(
                                    width: 6,
                                    height: 6,
                                  ),
                                  Text(
                                    formattedTime,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 7, 9, 10)),
                                  ),
                                ],
                              ),
                              Text(
                                widget.text,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ])
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // trailing: !isSpecificSender
            //     ? null
            //     : (senderData != null && senderData?['imageUri'] != null
            //         ? SizedBox(
            //             width: 30,
            //             height: 30,
            //             child: CircleAvatar(
            //               radius: 14,
            //               backgroundImage:
            //                   NetworkImage(senderData?['imageUri']),
            //             ),
            //           )
            //         : null),
          )
        : ListTile();
  }
}
