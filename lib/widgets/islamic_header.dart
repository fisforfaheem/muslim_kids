import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IslamicHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? avatarPath;
  final String userName;
  final bool isLoading;
  final VoidCallback? onLogoutPressed;
  final bool showLogout;
  final String? subtitle;

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
          ],
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 5,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundImage:
                        AssetImage(avatarPath ?? 'assets/avatar2.jpg'),
                    radius: 20,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLoading ? 'Loading...' : 'Welcome, $userName!',
                      style: GoogleFonts.quicksand(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: Colors.amber[100],
                        ),
                      ),
                  ],
                ),
              ),
              if (showLogout && onLogoutPressed != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.logout_rounded, color: Colors.amber[100]),
                    onPressed: onLogoutPressed,
                    tooltip: 'Logout',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
