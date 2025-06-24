import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_kids/welcome_page1.dart';
import 'package:muslim_kids/services/user_data_service.dart';
import 'package:muslim_kids/mixins/safe_state_mixin.dart';
import 'package:muslim_kids/widgets/loading_skeleton.dart';
import 'dart:async';

class SettingsPage extends StatefulWidget {
  final bool fromBottomNav;

  const SettingsPage({super.key, this.fromBottomNav = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SafeStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final UserDataService _userDataService = UserDataService();
  final _formKey = GlobalKey<FormState>();
  
  UserData? _userData;
  bool _isLoading = true;
  String? _errorMessage;
  late StreamSubscription<UserData?> _userDataSubscription;
  late StreamSubscription<bool> _loadingSubscription;
  late StreamSubscription<String?> _errorSubscription;

  // Avatar options
  List<String> avatarImages = [
    'assets/avatar1.jpg',
    'assets/avatar2.jpg',
    'assets/avatar3.jpg',
    'assets/avatar4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _initializeUserDataService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _userDataSubscription.cancel();
    _loadingSubscription.cancel();
    _errorSubscription.cancel();
    super.dispose();
  }

  /// Initialize user data service and set up listeners
  void _initializeUserDataService() {
    // Listen to user data changes
    _userDataSubscription = _userDataService.userDataStream.listen((userData) {
      safeSetState(() {
        _userData = userData;
        if (userData != null) {
          _nameController.text = userData.name;
          _emailController.text = userData.email;
        }
      });
    });

    // Listen to loading state changes
    _loadingSubscription = _userDataService.loadingStream.listen((loading) {
      safeSetState(() {
        _isLoading = loading;
      });
    });

    // Listen to error state changes
    _errorSubscription = _userDataService.errorStream.listen((error) {
      safeSetState(() {
        _errorMessage = error;
      });
      
      if (error != null) {
        showErrorMessage(error);
      }
    });

    // Initialize the service
    _userDataService.initialize();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _userDataService.updateUserData(
      name: _nameController.text.trim(),
      avatar: _userData?.avatar,
      email: _emailController.text.trim(),
    );

    if (success) {
      showSuccessMessage('Profile updated successfully');
      
      // Show email note if email was changed
      if (_userData?.email != _emailController.text.trim()) {
        showErrorMessage(
          'Email updated in profile. Note: Your login email remains unchanged.',
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  void _selectAvatar(String avatar) {
    // Update avatar through the service
    _userDataService.updateUserData(
      name: _userData?.name,
      avatar: avatar,
      email: _userData?.email,
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.pink[200],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false, // Disable automatic back button
            // Only show back button if not from bottom nav
            leading:
                widget.fromBottomNav
                    ? null
                    : IconButton(
                      icon: const Icon(Icons.arrow_back, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
            centerTitle: true,
            title: Text(
              'Settings',
              style: GoogleFonts.kanit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  16.0,
                  16.0,
                  16.0,
                  100.0,
                ), // Added extra bottom padding for navigation bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // Profile Section - Simplified
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Avatar
                            _isLoading && _userData == null
                                ? LoadingSkeleton(
                                    width: 80,
                                    height: 80,
                                    borderRadius: BorderRadius.circular(40),
                                  )
                                : CircleAvatar(
                                    radius: 40,
                                    backgroundImage: AssetImage(
                                      _userData?.avatar ?? 'assets/avatar2.jpg',
                                    ),
                                  ),
                            const SizedBox(width: 16),
                            // User info
                            Expanded(
                              child: _isLoading && _userData == null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        LoadingSkeleton(
                                          width: double.infinity,
                                          height: 20,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        const SizedBox(height: 8),
                                        LoadingSkeleton(
                                          width: 150,
                                          height: 14,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        const SizedBox(height: 8),
                                        LoadingSkeleton(
                                          width: 100,
                                          height: 20,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _userData?.name ?? 'User',
                                          style: GoogleFonts.kanit(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _userData?.email ?? '',
                                          style: GoogleFonts.kanit(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _userData?.userType == 'Kid'
                                                ? Colors.blue[100]
                                                : Colors.green[100],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            _userData?.userType == 'Kid'
                                                ? 'Kid Account'
                                                : 'Teacher Account',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _userData?.userType == 'Kid'
                                                  ? Colors.blue[800]
                                                  : Colors.green[800],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name field with more compact style
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: Icon(Icons.person),
                                  isDense: true, // Makes the field more compact
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Email field with more compact style
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                  isDense: true, // Makes the field more compact
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),

                              // Avatar selection (only for Kid accounts)
                              if (_userData?.userType == 'Kid') ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Choose Avatar:',
                                  style: GoogleFonts.kanit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children:
                                      avatarImages.map((avatar) {
                                        return GestureDetector(
                                          onTap: () => _selectAvatar(avatar),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    _userData?.avatar == avatar
                                                        ? Colors.pink
                                                        : Colors.transparent,
                                                width: 3,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              radius: 25, // Smaller radius
                                              backgroundImage: AssetImage(
                                                avatar,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ],

                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Update Profile',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Account Section - More compact
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      child: Column(
                        children: [
                          // Reset Password Option
                          ListTile(
                            dense: true, // Makes the tile more compact
                            leading: const Icon(
                              Icons.lock_reset,
                              color: Colors.orange,
                              size: 24,
                            ),
                            title: const Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text('Send password reset email'),
                            onTap: () {
                              _sendPasswordResetEmail();
                            },
                          ),
                          const Divider(height: 1),
                          // Logout Option
                          ListTile(
                            dense: true, // Makes the tile more compact
                            leading: const Icon(
                              Icons.exit_to_app,
                              color: Colors.red,
                              size: 24,
                            ),
                            title: const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text('Sign out from your account'),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Logout Confirmation'),
                                      content: const Text(
                                        'Are you sure you want to logout?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _logout();
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Logout'),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Add the password reset method
  Future<void> _sendPasswordResetEmail() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _userData?.email ?? '',
      );
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${_userData?.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
