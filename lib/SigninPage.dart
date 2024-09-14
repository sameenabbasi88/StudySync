import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to log session start
  Future<void> logSessionStart(String userId) async {
    String sessionId = DateTime.now().toIso8601String();
    await _firestore.collection('sessionLogs').add({
      'userId': userId,
      'startTime': Timestamp.now(),
      'endTime': null,
      'sessionId': sessionId,
    });
  }

  // Method to log session end
  Future<void> logSessionEnd(String userId) async {
    try {
      // Fetch the last session where endTime is null and update it
      QuerySnapshot querySnapshot = await _firestore
          .collection('sessionLogs')
          .where('userId', isEqualTo: userId)
          .where('endTime', isEqualTo: null)
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot lastSession = querySnapshot.docs.first;
        print("Updating session with ID: ${lastSession.id}");
        await lastSession.reference.update({'endTime': Timestamp.now()});
      } else {
        print("No active session found for user: $userId");
      }
    } catch (e) {
      print("Error updating session end time: $e");
    }
  }

  // Method to sign out
  Future<void> signOut() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await logSessionEnd(user.uid);
    }
    await FirebaseAuth.instance.signOut();
  }

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
        });

        // Log the session start
        await logSessionStart(user.uid);

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
              child: SingleChildScrollView(
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

  @override
  void dispose() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      logSessionEnd(user.uid).then((_) {
        print("Session ended for user: ${user.uid}");
      }).catchError((e) {
        print("Error ending session: $e");
      });
    }
    super.dispose();
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintText: 'Enter your email',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Call reset password logic
                          try {
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(
                              email: emailController.text,
                            );
                            Navigator.of(dialogContext).pop(); // Close dialog
                          } catch (e) {
                            // Handle error
                            print("Error sending password reset email: $e");
                          }
                        },
                        child: Text('Reset Password'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
