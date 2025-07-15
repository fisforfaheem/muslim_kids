import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A comprehensive navigation helper that provides guidance features
/// for parents and children to navigate the app effectively
class NavigationHelper {
  static const String _hasSeenTutorialKey = 'has_seen_tutorial';
  static const String _parentalGuidanceEnabledKey = 'parental_guidance_enabled';

  /// Shows an interactive tutorial for first-time users
  static Future<void> showAppTutorial(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool(_hasSeenTutorialKey) ?? false;

    if (!hasSeenTutorial && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AppTutorialDialog(),
      );
      await prefs.setBool(_hasSeenTutorialKey, true);
    }
  }

  /// Shows navigation help overlay
  static void showNavigationHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NavigationHelpDialog(),
    );
  }

  /// Shows feature-specific help
  static void showFeatureHelp(
    BuildContext context,
    String featureName,
    String description,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => FeatureHelpDialog(
            featureName: featureName,
            description: description,
          ),
    );
  }

  /// Checks if parental guidance is enabled
  static Future<bool> isParentalGuidanceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_parentalGuidanceEnabledKey) ?? true;
  }

  /// Toggles parental guidance settings
  static Future<void> toggleParentalGuidance(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_parentalGuidanceEnabledKey, enabled);
  }
}

/// Interactive tutorial dialog for first-time users
class AppTutorialDialog extends StatefulWidget {
  const AppTutorialDialog({super.key});

  @override
  State<AppTutorialDialog> createState() => _AppTutorialDialogState();
}

class _AppTutorialDialogState extends State<AppTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialStep> _tutorialSteps = [
    TutorialStep(
      title: 'Welcome to Muslim Kids! 🌟',
      description:
          'A safe and fun way to learn about Islam. Let\'s take a quick tour!',
      icon: Icons.mosque,
      color: Colors.blue,
    ),
    TutorialStep(
      title: 'Home Screen 🏠',
      description:
          'Tap on colorful tiles to explore different activities like prayers, quizzes, and videos.',
      icon: Icons.home,
      color: Colors.green,
    ),
    TutorialStep(
      title: 'Bottom Navigation 📱',
      description:
          'Use the bottom bar to switch between Home, Progress, Settings, and Notifications.',
      icon: Icons.navigation,
      color: Colors.purple,
    ),
    TutorialStep(
      title: 'Progress Tracking 📊',
      description:
          'Check your progress, earned points, and achievements in the Progress tab.',
      icon: Icons.trending_up,
      color: Colors.orange,
    ),
    TutorialStep(
      title: 'Need Help? 🆘',
      description:
          'Look for the help button (?) on any screen for guidance and tips.',
      icon: Icons.help,
      color: Colors.pink,
    ),
    TutorialStep(
      title: 'Ready to Start! 🚀',
      description:
          'You\'re all set! Remember, learning about Islam is a beautiful journey.',
      icon: Icons.star,
      color: Colors.amber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress indicator
            Row(
              children: List.generate(
                _tutorialSteps.length,
                (index) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color:
                          index <= _currentPage
                              ? Colors.blue
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tutorial content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _tutorialSteps.length,
                itemBuilder: (context, index) {
                  final step = _tutorialSteps[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: step.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(step.icon, size: 60, color: step.color),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        step.title,
                        style: GoogleFonts.kanit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: step.color,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 15),

                      Text(
                        step.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed:
                      _currentPage > 0
                          ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                          : null,
                  child: const Text('Previous'),
                ),

                Text(
                  '${_currentPage + 1} of ${_tutorialSteps.length}',
                  style: const TextStyle(color: Colors.grey),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _tutorialSteps.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tutorialSteps[_currentPage].color,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _currentPage < _tutorialSteps.length - 1
                        ? 'Next'
                        : 'Start Learning!',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

/// Navigation help dialog
class NavigationHelpDialog extends StatelessWidget {
  const NavigationHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue, size: 30),
                const SizedBox(width: 10),
                Text(
                  'Navigation Help',
                  style: GoogleFonts.kanit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ..._buildHelpItems(),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Got it!'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHelpItems() {
    final helpItems = [
      HelpItem(
        icon: Icons.home,
        title: 'Home Screen',
        description: 'Tap colorful tiles to access different features',
        color: Colors.green,
      ),
      HelpItem(
        icon: Icons.navigation,
        title: 'Bottom Navigation',
        description:
            'Switch between Home, Progress, Settings, and Notifications',
        color: Colors.purple,
      ),
      HelpItem(
        icon: Icons.arrow_back,
        title: 'Back Button',
        description: 'Use the back arrow to return to previous screen',
        color: Colors.orange,
      ),
      HelpItem(
        icon: Icons.settings,
        title: 'Settings',
        description: 'Adjust app preferences and account settings',
        color: Colors.pink,
      ),
    ];

    return helpItems
        .map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: item.color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

/// Feature-specific help dialog
class FeatureHelpDialog extends StatelessWidget {
  final String featureName;
  final String description;

  const FeatureHelpDialog({
    super.key,
    required this.featureName,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber, size: 40),
            const SizedBox(height: 15),
            Text(
              featureName,
              style: GoogleFonts.kanit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              description,
              style: const TextStyle(fontSize: 16, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
              child: const Text('Understood'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Help button widget that can be added to any screen
class HelpButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? helpText;

  const HelpButton({super.key, this.onPressed, this.helpText});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'help_button_${DateTime.now().millisecondsSinceEpoch}',
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      onPressed:
          onPressed ?? () => NavigationHelper.showNavigationHelp(context),
      child: const Icon(Icons.help_outline, size: 20),
    );
  }
}

/// Parental controls widget for navigation settings
class ParentalControlsWidget extends StatefulWidget {
  const ParentalControlsWidget({super.key});

  @override
  State<ParentalControlsWidget> createState() => _ParentalControlsWidgetState();
}

class _ParentalControlsWidgetState extends State<ParentalControlsWidget> {
  bool _guidanceEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await NavigationHelper.isParentalGuidanceEnabled();
    if (mounted) {
      setState(() {
        _guidanceEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleGuidance(bool value) async {
    setState(() => _guidanceEnabled = value);
    await NavigationHelper.toggleParentalGuidance(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Navigation guidance enabled'
                : 'Navigation guidance disabled',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.family_restroom,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Parental Navigation Controls',
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Navigation Guidance Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                title: Text(
                  'Navigation Guidance',
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  'Show help tips and tutorials for children',
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                value: _guidanceEnabled,
                onChanged: _toggleGuidance,
                activeColor: Colors.green.shade600,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),

            const SizedBox(height: 12),

            // Show App Tutorial Button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Show App Tutorial',
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  'Replay the welcome tutorial',
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                onTap: () => NavigationHelper.showAppTutorial(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),

            const SizedBox(height: 12),

            // Navigation Help Button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Navigation Help',
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  'View navigation tips and tricks',
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                onTap: () => NavigationHelper.showNavigationHelp(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data models for tutorial and help system
class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class HelpItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  HelpItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
