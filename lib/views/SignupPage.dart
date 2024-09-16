import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled/views/studysyncmain.dart';

class StudySyncSignupApp extends StatefulWidget {
  @override
  _StudySyncSignupAppState createState() => _StudySyncSignupAppState();
}

class _StudySyncSignupAppState extends State<StudySyncSignupApp> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Create a new user with Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Get user ID
        String userId = userCredential.user?.uid ?? '';

        // Save user data in Firestore, including signup date
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'username': _usernameController.text,
          'email': _emailController.text,
          'date': DateTime.now(), // Add the current date and time
        });

        // Navigate to StudySyncMain page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudySyncDashboard(userId: '',)), // Replace with your actual main page widget
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Successful')),
        );
      } on FirebaseAuthException catch (e) {
        // Handle sign-up errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: Color(0xFFc1121f),
      ),
      body: Container(
        color: Color(0xFFfae5d3),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 70),
            Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Enter User Name',
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.black87),
                    ),
                    style: TextStyle(color: Colors.black87),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.black87),
                    ),
                    style: TextStyle(color: Colors.black87),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.black87),
                    ),
                    obscureText: true,
                    style: TextStyle(color: Colors.black87),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _signUp,
                    child: Text('Sign Up', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFc1121f),
                    ),
                  ),
                  SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Already registered? Sign In',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
