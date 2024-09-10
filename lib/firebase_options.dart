import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'SigninPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCHRcYLl0Z20namsU90hqv4NFT_jSD92Xk",
        authDomain: "studysync-a5b9f.firebaseapp.com",
        projectId: "studysync-a5b9f",
        storageBucket: "studysync-a5b9f.appspot.com",
        messagingSenderId: "81256495954",
        appId: "1:81256495954:web:071eea1e4c658bbb72988b",
        measurementId: "G-HBJD4YEW92"
    ),
  );
  runApp(StudySyncLoginApp());
}
