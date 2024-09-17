import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firbase_options.dart';
import 'providers/Friend_Provider.dart';
import 'providers/timer_provider.dart'; // Import TimerProvider
import 'views/SigninPage.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptionsConfig.firebaseOptions,
  );

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
      home: StudySyncLoginApp(),
    );
  }
}
