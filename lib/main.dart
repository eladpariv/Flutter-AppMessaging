import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_app/Screens/ChatsGroupsScreen.dart';
import 'package:my_flutter_app/Screens/ProfileScreen.dart';
import 'package:my_flutter_app/api/firebase_api.dart';
import 'package:my_flutter_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Screens/HomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Screens/LoginScreen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Set this to false
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      home: FirebaseAuth.instance.currentUser == null
          ? LoginScreen()
          : const MyHomePage(),
      routes: {
        NotificationScreen.route: (context) => const NotificationScreen()
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.face_outlined),
              label: 'Profile',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.home_outlined),
            //   label: 'Home',
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              label: 'Messages',
            ),
          ],
        ),
        body: _currentIndex == 0
            ? ProfileScreen()
            :
            // : _currentIndex == 1
            // ? const HomeScreen()
            const NotificationScreen());
  }
}
