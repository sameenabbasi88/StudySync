import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/views/studysyncmain.dart';

import 'SignupPage.dart';

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

class _StudySyncLoginPageState extends State<StudySyncLoginPage> with WidgetsBindingObserver {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? currentUser;
  bool _isLoading = false;
  bool _obscureText=true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentUser = FirebaseAuth.instance.currentUser;

    // Set online status on initialization
    if (currentUser != null) {
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Set offline status when disposing
    if (currentUser != null) {
    }

    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true; // Show the loading indicator
    });

    // Validate email and password fields
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _isLoading = false; // Hide the loading indicator
      });
      showErrorDialog('Email and password cannot be empty.');
      return; // Exit the method
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Update online status
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': true,
        });
        currentUser = user;

        // Navigate to StudySyncMainPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => StudySyncDashboard(userId: user.uid)),
        );
      }
    } catch (e) {
      // Show error dialog for wrong credentials
      showErrorDialog('Incorrect credentials. Please try again.');
      print('Error signing in: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide the loading indicator
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Failed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  TextStyle _responsiveTextStyle(double baseFontSize, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Adjust font size for different screen widths
    double fontSize = baseFontSize;
    if (screenWidth < 600) {
      fontSize = baseFontSize * 0.65;  // Decrease font size on mobile devices
    }

    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'images/bg.jpg',
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
                    if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(), // Show loading spinner
                      )else
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WELCOME !',
                                  style: _responsiveTextStyle(36, context),  // Base font size is 36
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
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.black87,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureText = !_obscureText;
                                        });
                                      },
                                    ),
                                    labelText: 'Password',
                                    border: OutlineInputBorder(),
                                    labelStyle: TextStyle(color: Colors.black87),
                                  ),
                                  obscureText: _obscureText, // Use the _obscureText variable to toggle visibility
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
                      margin: EdgeInsets.only(top: 50),
                      child: Align(
                        alignment: Alignment.center,  // Ensures the text is centered horizontally
                        child: Text(
                          'StudySync',
                          textAlign: TextAlign.center,  // Center the text within the container
                          style: _responsiveTextStyle(36, context),  // Use responsive font size
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
                    SizedBox(height: 10),
                    Text(
                      'A password reset will be sent to the email entered.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70, // A softer white color
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the button
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: emailController.text);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('Password reset email sent')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('Error sending email')),
                          );
                        }
                      },
                      child: Text('Send Reset Link'),
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