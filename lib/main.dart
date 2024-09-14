import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'SigninPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Initialize Firebase for web
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyA3Eu-HgMmYxEsk33FQ0wtq_Ro3_gVp2PY",
        authDomain: "studysync-84b8f.firebaseapp.com",
        projectId: "studysync-84b8f",
        storageBucket: "studysync-84b8f.appspot.com",
        messagingSenderId: "593364241464",
        appId: "1:593364241464:web:0ef9917404222fd2226acd",
        measurementId: "G-FCP2YSKDJ2",
      ),
    );
  } else {
    // Initialize Firebase for mobile/other platforms
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Study_Sync',
      debugShowCheckedModeBanner: false,
      home: const StudySyncLoginApp(),
    );
  }
}
