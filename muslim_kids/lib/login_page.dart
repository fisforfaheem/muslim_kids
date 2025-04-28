import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isKidProfile = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  void login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = _auth.currentUser!.uid;

      // Fetch user details from Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw FirebaseAuthException(
            code: 'user-not-found', message: 'User data not found.');
      }

      String userType = userDoc['userType']; // Either 'Kid' or 'Teacher
      String email = userDoc['email'];

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(
                    userType: userType,
                    email: email,
                  )),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Try again.';
      } else {
        errorMessage = e.message ?? 'Something went wrong.';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Login Failed'),
              content: Text(errorMessage),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  void resetPassword() async {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Please enter your email address.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Password Reset Email Sent'),
              content: const Text(
                  'Check your email for instructions to reset your password.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address.';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else {
        errorMessage = e.message ?? 'Something went wrong.';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(errorMessage),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Prevent content from moving up when keyboard appears
      backgroundColor: const Color.fromARGB(255, 255, 244, 143),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment
                .center, // Ensures the content is centered vertically and horizontally
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundImage: AssetImage('assets/child.jpg'),
                ),
                const SizedBox(height: 10),
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'MuslimKids',
                      textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                      speed: Duration(milliseconds: 200),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() => isKidProfile = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isKidProfile ? Colors.blue : Colors.white,
                        foregroundColor:
                            isKidProfile ? Colors.white : Colors.black,
                      ),
                      child: const Text('Kid Profile',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => setState(() => isKidProfile = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !isKidProfile ? Colors.blue : Colors.white,
                        foregroundColor:
                            !isKidProfile ? Colors.white : Colors.black,
                      ),
                      child: const Text('Teacher Profile',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password', border: OutlineInputBorder()),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(value: false, onChanged: (value) {}),
                    const Text('Remember me',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Login',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: resetPassword,
                      child: const Text('Forgot Password?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    TextButton(
                      onPressed: navigateToRegister,
                      child: const Text('New User? Register',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
