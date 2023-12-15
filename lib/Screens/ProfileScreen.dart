import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_flutter_app/Screens/LoginScreen.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> _logout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  } catch (e) {
    // Handle logout error
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout Failed'),
          content: Text(e.toString() ?? 'An error occurred.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Upload the image to Firestore
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    try {
      if (FirebaseAuth.instance.currentUser != null && _image != null) {
        String userId = FirebaseAuth.instance.currentUser!.uid;

        await FirebaseStorage.instance
            .ref()
            .child('user_images/$userId/profile_image.jpg')
            .putFile(_image!);

        // Get the download URL
        String downloadURL = await FirebaseStorage.instance
            .ref()
            .child('user_images/$userId/profile_image.jpg')
            .getDownloadURL();

        // Update the user document in Firestore with the image URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'imageUri': downloadURL,
        });
      }
    } catch (e) {
      // Handle image upload error
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Image Upload Failed'),
            content: Text(e.toString() ?? 'An error occurred.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  final StreamController<String> _imageUriController =
      StreamController<String>();
  String? _imageUri;

  @override
  void initState() {
    super.initState();
    _initImageUri();
  }

  void _initImageUri() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            String? newImageUri = snapshot['imageUri'];
            setState(() {
              _imageUri = newImageUri;
            });
            _imageUriController.add(newImageUri ?? '');
          }
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout_outlined),
        ),
      ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageUri != null
                ? Stack(children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(_imageUri!),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      right: -10,
                      child: IconButton(
                          style: ButtonStyle(
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.white)),
                          color: Colors.black,
                          onPressed: _getImage,
                          icon: const Icon(
                            size: 15,
                            Icons.image_outlined,
                          )),
                    ),
                  ])
                : Container(),
          ],
        ),
      ),
    );
  }
}
