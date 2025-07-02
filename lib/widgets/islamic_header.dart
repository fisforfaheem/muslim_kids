import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'navigation_helper.dart';

class IslamicHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? avatarPath;
  final String userName;
  final bool isLoading;
  final VoidCallback? onLogoutPressed;
  final bool showLogout;
  final String? subtitle;
  final bool showHelp;

  @override
  final Size preferredSize;

  const IslamicHeader({
    super.key,
    this.avatarPath,
    required this.userName,
    this.isLoading = false,
    this.onLogoutPressed,
    this.showLogout = true,
    this.subtitle = 'May Allah bless your day',
    this.showHelp = true,
    this.preferredSize = const Size.fromHeight(80),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F4E5F),
            Color(0xFF2E7D32),
          ], // Back to original teal/green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber,
                        width: 3,
                      ), // Fun amber border
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withAlpha(100),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundImage: AssetImage(
                      avatarPath ?? 'assets/avatar2.jpg',
                    ),
                    radius: 22,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLoading ? 'Loading...' : 'Welcome, $userName!',
                      style: GoogleFonts.quicksand(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber[100], // Fun amber accent
                          letterSpacing: 0.2,
                        ),
                      ),
                  ],
                ),
              ),
              if (showHelp)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(80),
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed:
                        () => NavigationHelper.showNavigationHelp(context),
                    tooltip: 'Need Help?',
                    splashColor: Colors.white.withAlpha(60),
                    highlightColor: Colors.white.withAlpha(30),
                    iconSize: 20,
                  ),
                ),
              if (showLogout && onLogoutPressed != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(80), // Fun amber background
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.amber.withAlpha(120),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withAlpha(60),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: onLogoutPressed,
                    tooltip: 'Logout',
                    splashColor: Colors.amber.withAlpha(100),
                    highlightColor: Colors.amber.withAlpha(50),
                    iconSize: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
