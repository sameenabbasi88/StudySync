import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/providers/todo_provider.dart';
import 'package:untitled/views/SigninPage.dart';
import 'package:untitled/views/studysyncmain.dart';
import 'firbase_options.dart';
import 'providers/Friend_Provider.dart';
import 'providers/timer_provider.dart'; // Import TimerProvider


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptionsConfig.firebaseOptions,
  );

  // Set Firebase Auth Persistence
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()), // Add TimerProvider here
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study_Sync',
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(), // Use a wrapper to determine auth state
    );
  }
}

// A wrapper that checks Firebase authentication state and routes to the appropriate page
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Show a loading indicator
        }
        if (snapshot.hasData) {
          // User is signed in, show the dashboard
          return StudySyncDashboard(userId: snapshot.data!.uid); // Pass userId to dashboard
        } else {
          // User is not signed in, show the sign-in page
          return StudySyncLoginApp();
        }
      },
    );
  }
}
