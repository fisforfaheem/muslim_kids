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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  void login() async {
    // Hide keyboard when login is pressed
    FocusScope.of(context).unfocus();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
        // Sign out the user since their data doesn't exist
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-data-not-found',
          message: 'User profile not found. Please contact support.',
        );
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userType = userData['userType'] ?? '';
      String email = userData['email'] ?? '';
      String name = userData['name'] ?? '';
      String avatar = userData['avatar'] ?? 'assets/avatar2.jpg';

      // Check if userType is valid
      if (userType.isEmpty || (userType != 'Kid' && userType != 'Teacher')) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'invalid-user-type',
          message: 'Invalid account type. Please contact support.',
        );
      }

      // Validate role-based authentication
      String selectedRole = isKidProfile ? 'Kid' : 'Teacher';
      String actualRole = userType;

      // Check if selected role matches actual role
      if (selectedRole != actualRole) {
        // Sign out the user since role doesn't match
        await _auth.signOut();

        String errorMessage =
            selectedRole == 'Kid'
                ? 'This account is registered as a Teacher. Please select "Teacher Profile" and try again.'
                : 'This account is registered as a Student. Please select "Kid Profile" and try again.';

        throw FirebaseAuthException(
          code: 'role-mismatch',
          message: errorMessage,
        );
      }

      // Success - role matches, proceed to home page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => HomePage(
                  userType: userType,
                  email: email,
                  name: name,
                  avatar: avatar,
                ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';

      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Try again.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled.';
      } else if (e.code == 'too-many-requests') {
        errorMessage =
            'Too many failed login attempts. Please try again later.';
      } else if (e.code == 'role-mismatch') {
        errorMessage = e.message!;
      } else if (e.code == 'user-data-not-found') {
        errorMessage = e.message!;
      } else if (e.code == 'invalid-user-type') {
        errorMessage = e.message!;
      } else {
        errorMessage = e.message ?? 'Something went wrong.';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  Icon(
                    e.code == 'role-mismatch'
                        ? Icons.security
                        : Icons.error_outline,
                    color:
                        e.code == 'role-mismatch' ? Colors.orange : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  const Text('Login Failed'),
                ],
              ),
              content: Text(errorMessage, style: const TextStyle(fontSize: 16)),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Handle any other unexpected errors
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Error'),
                ],
              ),
              content: const Text(
                'An unexpected error occurred. Please try again.',
                style: TextStyle(fontSize: 16),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void resetPassword() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

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

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Password Reset Email Sent'),
              content: const Text(
                'Check your email for instructions to reset your password.',
              ),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard when tapping outside of text fields
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color.fromARGB(255, 255, 244, 143),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: const AssetImage('assets/child.jpg'),
                    ),
                    const SizedBox(height: 10),
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'Muslim Kids',
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          speed: const Duration(milliseconds: 200),
                        ),
                      ],
                      totalRepeatCount: 1,
                    ),
                    const SizedBox(height: 25),

                    // Role Selection Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Select Your Role',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () => setState(() => isKidProfile = true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isKidProfile
                                            ? Colors.blue.shade600
                                            : Colors.grey.shade200,
                                    foregroundColor:
                                        isKidProfile
                                            ? Colors.white
                                            : Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color:
                                            isKidProfile
                                                ? Colors.blue.shade600
                                                : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.child_care,
                                    size: 20,
                                    color:
                                        isKidProfile
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                  ),
                                  label: const Text(
                                    'Student',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () =>
                                          setState(() => isKidProfile = false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        !isKidProfile
                                            ? Colors.green.shade600
                                            : Colors.grey.shade200,
                                    foregroundColor:
                                        !isKidProfile
                                            ? Colors.white
                                            : Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color:
                                            !isKidProfile
                                                ? Colors.green.shade600
                                                : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.school,
                                    size: 20,
                                    color:
                                        !isKidProfile
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                  ),
                                  label: const Text(
                                    'Teacher',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please select your account type before logging in',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : resetPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : navigateToRegister,
                          child: const Text(
                            'New User? Register',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
