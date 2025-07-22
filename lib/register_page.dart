import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:muslim_kids/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muslim_kids/widgets/app_help_guide.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isKidProfile = true;
  bool isLoading = false;

  List<String> avatarImages = [
    'assets/avatar1.jpg',
    'assets/avatar2.jpg',
    'assets/avatar3.jpg',
    'assets/avatar4.jpg',
  ];
  String selectedAvatar = 'assets/child.jpg'; // Default avatar
  String? highlightedAvatar; // Tracks the avatar being highlighted

  void navigateToLogin() {
    Navigator.pop(context);
  }

  Future<void> register() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }

    // Ensure avatar is selected for kid profiles
    if (isKidProfile && highlightedAvatar == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an avatar')));
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // Save the selectedAvatar (which is now properly updated when an avatar is chosen)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': emailController.text.trim(),
            'name': nameController.text.trim(),
            'userType':
                isKidProfile
                    ? 'Kid'
                    : 'Teacher', // Always use 'Kid' or 'Teacher' for consistency
            'avatar': isKidProfile ? selectedAvatar : '',
            'uid':
                userCredential
                    .user!
                    .uid, // Store UID in the document for reference
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      // Create a full-screen dialog that blocks interaction with background
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Success Dialog',
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation1, animation2) {
          return PopScope(
            canPop: false, // Prevent dialog dismissal with back button
            child: Scaffold(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/success.json',
                      width: 180,
                      height: 180,
                      repeat: false,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Account Created Successfully!',
                      style: GoogleFonts.kanit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      // Wait a moment and then navigate to home
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Navigate directly to HomePage, replacing all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (context) => HomePage(
                userType: isKidProfile ? 'Kid' : 'Teacher',
                email: emailController.text.trim(),
                name: nameController.text.trim(),
                avatar: isKidProfile ? selectedAvatar : '',
              ),
        ),
        (route) => false, // Remove all previous routes
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = e.message ?? 'Registration failed';
      if (e.code == 'invalid-email') {
        errorMessage = 'Enter a valid email, like name@example.com';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromARGB(255, 255, 244, 143),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: AssetImage(selectedAvatar),
                      ),
                      const SizedBox(height: 10),
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'MuslimKids',
                            textStyle: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
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
                            onPressed:
                                () => setState(() => isKidProfile = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isKidProfile ? Colors.blue : Colors.white,
                              foregroundColor:
                                  isKidProfile ? Colors.white : Colors.black,
                            ),
                            child: const Text(
                              'Kid Profile',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed:
                                () => setState(() => isKidProfile = false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  !isKidProfile ? Colors.blue : Colors.white,
                              foregroundColor:
                                  !isKidProfile ? Colors.white : Colors.black,
                            ),
                            child: const Text(
                              'Teacher Profile',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Show Avatar selection only for Kid Profile
                      if (isKidProfile) ...[
                        Text(
                          'Choose Your Avatar:',
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(avatarImages.length, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  // Set highlighted avatar when tapped, without changing selectedAvatar
                                  highlightedAvatar = avatarImages[index];
                                  // Also update the selected avatar for display
                                  selectedAvatar = avatarImages[index];
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          highlightedAvatar ==
                                                  avatarImages[index]
                                              ? Colors
                                                  .pink // Highlight with pink color
                                              : Colors
                                                  .transparent, // Default transparent border
                                      width: 3,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundImage: AssetImage(
                                      avatarImages[index],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: navigateToLogin,
                        child: const Text(
                          "I'm already a user! Login Now",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
