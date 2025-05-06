# Islamic Header Usage Guide

The app now features a modern, Islamic-themed header that should be used consistently across all pages for a unified experience.

## How to Use the Islamic Header

1. First, import the header in your page:
```dart
import 'package:muslim_kids/widgets/islamic_header.dart';
```

2. Use it as your AppBar:
```dart
appBar: IslamicHeader(
  avatarPath: userAvatar,
  userName: userName ?? 'User',
  isLoading: isLoading,
  onLogoutPressed: logoutFunction,
),
```

## Parameters

The IslamicHeader widget accepts the following parameters:

- `avatarPath` (String?): Path to the user's avatar image (default: 'assets/avatar2.jpg')
- `userName` (String): User's name to display in the welcome message
- `isLoading` (bool): Whether to show a loading state (default: false)
- `onLogoutPressed` (VoidCallback?): Function to call when logout button is pressed
- `showLogout` (bool): Whether to show the logout button (default: true)
- `subtitle` (String?): Optional subtitle text (default: 'May Allah bless your day')
- `preferredSize` (Size): Size of the header (default: Size.fromHeight(80))

## Example

Here's a complete example of using the header in a page:

```dart
import 'package:flutter/material.dart';
import 'package:muslim_kids/widgets/islamic_header.dart';

class MyFeaturePage extends StatelessWidget {
  final String userName;
  final String? avatarPath;
  
  const MyFeaturePage({
    Key? key, 
    required this.userName,
    this.avatarPath,
  }) : super(key: key);
  
  void _handleLogout() {
    // Logout logic here
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 244, 143),
      appBar: IslamicHeader(
        avatarPath: avatarPath,
        userName: userName,
        onLogoutPressed: _handleLogout,
        subtitle: 'Feature Page Subtitle', // Optional custom subtitle
      ),
      body: Center(
        child: Text('My Feature Content'),
      ),
    );
  }
}
```

## Design Notes

The header features:
- Islamic green gradient background
- Gold-outlined avatar image
- Welcome message with blessing text
- Elegant rounded bottom corners
- Subtle shadow for depth

This design was chosen to reflect Islamic aesthetics while maintaining a modern, clean look that appeals to children. 