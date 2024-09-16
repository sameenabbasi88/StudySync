// firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseOptionsConfig {
  static FirebaseOptions get firebaseOptions {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: "AIzaSyA3Eu-HgMmYxEsk33FQ0wtq_Ro3_gVp2PY",
        authDomain: "studysync-84b8f.firebaseapp.com",
        projectId: "studysync-84b8f",
        storageBucket: "studysync-84b8f.appspot.com",
        messagingSenderId: "593364241464",
        appId: "1:593364241464:web:0ef9917404222fd2226acd",
        measurementId: "G-FCP2YSKDJ2",
      );
    } else {
      return FirebaseOptions(
        apiKey: "AIzaSyA3Eu-HgMmYxEsk33FQ0wtq_Ro3_gVp2PY",
        authDomain: "studysync-84b8f.firebaseapp.com",
        projectId: "studysync-84b8f",
        storageBucket: "studysync-84b8f.appspot.com",
        messagingSenderId: "593364241464",
        appId: "1:593364241464:web:0ef9917404222fd2226acd",
        measurementId: "G-FCP2YSKDJ2",
      );
    }
  }
}
