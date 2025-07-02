import 'package:flutter/material.dart';
import 'package:muslim_kids/widgets/navigation_helper.dart';

/// Demonstration of Navigation Helper Features
///
/// This file demonstrates how to integrate the comprehensive navigation
/// guidance system throughout the Muslim Kids app.
class NavigationHelperDemo {
  /// Example 1: Show tutorial for first-time users
  /// Call this in initState() of your main screen
  static void showWelcomeTutorial(BuildContext context) {
    // This automatically checks if user has seen tutorial before
    NavigationHelper.showAppTutorial(context);
  }

  /// Example 2: Add help button to any screen
  /// Use this as a floating action button or in app bar actions
  static Widget createHelpButton({VoidCallback? customAction}) {
    return HelpButton(
      onPressed: customAction,
      helpText: "Tap for help and guidance",
    );
  }

  /// Example 3: Show feature-specific help
  /// Call this from help buttons on specific feature screens
  static void showQuizzesHelp(BuildContext context) {
    NavigationHelper.showFeatureHelp(
      context,
      'Quranic Quizzes',
      'Test your knowledge of the Quran and Islamic teachings. Complete quizzes to earn points and unlock achievements. Tap on any quiz to start learning!',
    );
  }

  static void showPrayerTrackerHelp(BuildContext context) {
    NavigationHelper.showFeatureHelp(
      context,
      'Prayer Tracker',
      'Track your daily prayers and build a streak! Tap the checkboxes to mark prayers as completed. Keep track of your progress and earn rewards for consistency.',
    );
  }

  static void showProgressHelp(BuildContext context) {
    NavigationHelper.showFeatureHelp(
      context,
      'My Progress',
      'Track your learning journey! View your quiz statistics, earned points, achievements, and recent activity. Keep learning to unlock more badges and improve your scores.',
    );
  }

  /// Example 4: Show general navigation help
  /// This shows an overview of how to navigate the app
  static void showGeneralNavigationHelp(BuildContext context) {
    NavigationHelper.showNavigationHelp(context);
  }

  /// Example 5: Check if parental guidance is enabled
  /// Use this to conditionally show guidance features
  static Future<bool> shouldShowGuidance() async {
    return await NavigationHelper.isParentalGuidanceEnabled();
  }

  /// Example 6: Toggle parental guidance
  /// Use this in settings or parental controls
  static Future<void> toggleGuidance(bool enabled) async {
    await NavigationHelper.toggleParentalGuidance(enabled);
  }
}

/// Example integration in a feature screen
class ExampleFeatureScreen extends StatelessWidget {
  const ExampleFeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example Feature'),
        actions: [
          // Add help button to app bar
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed:
                () => NavigationHelper.showFeatureHelp(
                  context,
                  'Example Feature',
                  'This is how you add help to any feature screen. Explain what the feature does and how to use it.',
                ),
          ),
        ],
      ),
      body: const Center(child: Text('Feature content goes here')),
      // Note: Help button is now integrated in the Islamic header
    );
  }
}

/// Example integration in settings
class ExampleSettingsIntegration extends StatelessWidget {
  const ExampleSettingsIntegration({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            // Other settings widgets...

            // Add parental controls widget
            ParentalControlsWidget(),

            // Other settings widgets...
          ],
        ),
      ),
    );
  }
}

/// Usage Examples:
/// 
/// 1. In your main home screen initState():
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   WidgetsBinding.instance.addPostFrameCallback((_) {
///     NavigationHelper.showAppTutorial(context);
///   });
/// }
/// ```
/// 
/// 2. Help button is integrated in Islamic header:
/// ```dart
/// appBar: IslamicHeader(showHelp: true), // Help button included by default
/// ```
/// 
/// 3. Add help to app bar:
/// ```dart
/// actions: [
///   IconButton(
///     icon: const Icon(Icons.help_outline),
///     onPressed: () => NavigationHelper.showFeatureHelp(
///       context,
///       'Feature Name',
///       'Feature description and usage instructions.',
///     ),
///   ),
/// ],
/// ```
/// 
/// 4. Add parental controls to settings:
/// ```dart
/// const ParentalControlsWidget(),
/// ```
/// 
/// 5. Check guidance settings:
/// ```dart
/// final shouldShow = await NavigationHelper.isParentalGuidanceEnabled();
/// if (shouldShow) {
///   // Show guidance features
/// }
/// ``` 