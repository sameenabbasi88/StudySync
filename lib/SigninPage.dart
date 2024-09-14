import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore import
import 'package:untitled/studysyncmain.dart';

import 'SignupPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
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
    await Firebase.initializeApp();
  }

  runApp(const StudySyncLoginApp());
}

class StudySyncLoginApp extends StatelessWidget {
  const StudySyncLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StudySyncLoginPage(),
    );
  }
}

class StudySyncLoginPage extends StatefulWidget {
  @override
  _StudySyncLoginPageState createState() => _StudySyncLoginPageState();
}

class _StudySyncLoginPageState extends State<StudySyncLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore
      .instance; // Firestore instance

  Future<void> _signIn() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Update last login timestamp
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          // Store the server timestamp
        });

        // Navigate to StudySyncMainPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => StudySyncDashboard(userId: user.uid)),
        );
      }
    } catch (e) {
      // Handle error
      print('Error signing in: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg.jpg',
            fit: BoxFit.cover,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView( // Added SingleChildScrollView
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WELCOME !',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 70),
                              Text(
                                'Sign in',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 20),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  border: OutlineInputBorder(),
                                  labelStyle: TextStyle(color: Colors.black87),
                                ),
                                style: TextStyle(color: Colors.black87),
                              ),
                              SizedBox(height: 20),
                              TextField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
                                  labelStyle: TextStyle(color: Colors.black87),
                                ),
                                obscureText: true,
                                style: TextStyle(color: Colors.black87),
                              ),
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return ForgotPasswordDialog();
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 0.0),
                                  child: Text(
                                    'Forget password?',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ),
                              ),

                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _signIn,
                                child: Text('Sign In',
                                    style: TextStyle(color: Colors.black87)),
                              ),
                              SizedBox(height: 10),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) =>
                                        StudySyncSignupApp()),
                                  );
                                },
                                child: Text(
                                  'Not registered yet? Signup',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 340, top: 50),
                      child: Text(
                        'StudySync',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Builder(
        builder: (dialogContext) {
          return Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF01323C), // Dark teal background color
              borderRadius: BorderRadius.circular(10),
            ),
            height: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Forget Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),

                // Email Input Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Email',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'A password reset link will be sent to the email entered.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

                // Send Email Button
                ElevatedButton(
                  onPressed: () async {
                    String email = emailController.text;
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      // Close the dialog after a short delay
                      Future.delayed(Duration(seconds: 1), () {
                        Navigator.of(context).pop();
                      });
                    } catch (e) {
                      // Handle errors here if needed, but no SnackBar
                    }
                  },
                  child: Text('Send Email', style: TextStyle(color: Colors.black87)),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}



