import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_kids/services/quiz_service.dart';
import 'package:muslim_kids/Features/quizzes_page.dart';
import 'package:intl/intl.dart';
import 'package:muslim_kids/models/badge_model.dart';
import 'package:muslim_kids/services/badge_service.dart';
import 'package:muslim_kids/widgets/navigation_helper.dart';

class ProgressPage extends StatefulWidget {
  final bool fromBottomNav;

  const ProgressPage({super.key, this.fromBottomNav = false});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with SingleTickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  late TabController _tabController;
  bool _isLoading = true;
  int _totalPoints = 0;
  int _completedQuizzes = 0;
  double _averageScore = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  final BadgeService _badgeService = BadgeService();
  List<BadgeModel> _allBadges = [];
  List<String> _earnedBadgeIds = [];
  bool _isLoadingBadges = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProgress();
    _loadBadges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Additional state variables for improved progress tracking
  int _uniqueQuizzes = 0;
  double _bestScore = 0.0;
  int _totalTimeSpent = 0;

  Future<void> _loadUserProgress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user quiz statistics and history
      final statistics = await _quizService.getUserQuizStatistics();

      // We don't need to fetch history separately anymore since statistics now includes all results
      final history = statistics['recentResults'] as List<Map<String, dynamic>>;

      // Extract data from statistics with improved accuracy
      final completedQuizzes = statistics['quizzesCompleted'] ?? 0;
      final uniqueQuizzes = statistics['uniqueQuizzes'] ?? 0;
      final points = statistics['totalPoints'] ?? 0;
      final avgScore = statistics['averageScore'] ?? 0.0;
      final bestScore = statistics['bestScore'] ?? 0.0;
      final totalTimeSpent = statistics['totalTimeSpent'] ?? 0;

      // Convert history to activity feed
      List<Map<String, dynamic>> activity = [];

      for (var result in history) {
        final score = result['score'] as int;
        final totalQuestions = result['totalQuestions'] as int;
        final quizTitle = result['quizTitle'] as String;
        final completedAt = result['completedAt'] as DateTime;
        final earnedPoints =
            result['earnedPoints'] as int? ??
            (result['percentage'] as num? ?? 0) ~/ 10;
        final timeSpent = result['timeSpentInSeconds'] as int? ?? 0;

        double scorePercentage = score / totalQuestions;

        activity.add({
          'title': quizTitle,
          'date': completedAt,
          'score': scorePercentage,
          'points': earnedPoints,
          'timeSpent': timeSpent,
          'type': 'quiz_completed',
        });
      }

      // Sort activity by date (newest first)
      activity.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

      setState(() {
        _totalPoints = points;
        _completedQuizzes = completedQuizzes;
        _uniqueQuizzes = uniqueQuizzes;
        _averageScore = avgScore / 100; // Convert to 0-1 scale
        _bestScore = bestScore / 100; // Convert to 0-1 scale
        _totalTimeSpent = totalTimeSpent;
        _recentActivity = activity;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading progress: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBadges() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBadges = true;
    });
    _allBadges = _badgeService.getAvailableBadges();
    _earnedBadgeIds = await _badgeService.getEarnedBadgeIds();
    if (mounted) {
      setState(() {
        _isLoadingBadges = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 244, 143),
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
            title: Text(
              'My Progress',
              style: GoogleFonts.kanit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions:
                widget.fromBottomNav
                    ? null
                    : [
                      IconButton(
                        icon: const Icon(Icons.help_outline, size: 28),
                        onPressed:
                            () => NavigationHelper.showFeatureHelp(
                              context,
                              'My Progress',
                              'Track your learning journey! View your quiz statistics, earned points, achievements, and recent activity. Keep learning to unlock more badges and improve your scores.',
                            ),
                      ),
                    ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [Tab(text: 'OVERVIEW'), Tab(text: 'ACHIEVEMENTS')],
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [_buildOverviewTab(), _buildAchievementsTab()],
              ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadUserProgress,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key stats cards - now with more detailed information
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Points',
                    _totalPoints.toString(),
                    Icons.workspace_premium,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Quizzes Completed',
                    '$_completedQuizzes',
                    Icons.school,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Second row of stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Unique Quizzes',
                    _uniqueQuizzes.toString(),
                    Icons.category,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Best Score',
                    '${(_bestScore * 100).toInt()}%',
                    Icons.star,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Time spent card
            _buildStatCard(
              'Total Time Spent',
              _formatTime(_totalTimeSpent),
              Icons.timer,
              Colors.purple,
              fullWidth: true,
            ),

            const SizedBox(height: 16),

            // Average score card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Average Score',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Circular progress indicator
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getScoreColor(_averageScore),
                            width: 8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${(_averageScore * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getScoreMessage(_averageScore),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(_averageScore),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Keep taking quizzes to improve your knowledge and score!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent activity section
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 12),

            _recentActivity.isEmpty
                ? _buildEmptyState(
                  'No activity yet',
                  'Start taking quizzes to see your progress here.',
                )
                : Column(
                  children:
                      _recentActivity
                          .map((activity) => _buildActivityItem(activity))
                          .toList(),
                ),

            const SizedBox(height: 24),

            // Take more quizzes button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuizzesPage(),
                    ),
                  ).then((_) => _loadUserProgress());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[200],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Take More Quizzes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    if (_isLoadingBadges) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allBadges.isEmpty) {
      return const Center(
        child: Text(
          'No achievements available yet.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBadges,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _allBadges.length,
        itemBuilder: (context, index) {
          final badge = _allBadges[index];
          final isEarned = _earnedBadgeIds.contains(badge.id);
          return BadgeCard(badge: badge, isEarned: isEarned);
        },
      ),
    );
  }

  // Format seconds into a readable time string (HH:MM:SS or MM:SS)
  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '$minutes min ${remainingSeconds > 0 ? '$remainingSeconds sec' : ''}';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51), // 0.2 opacity
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final dateFormat = DateFormat('dd MMM, yyyy');
    final scoreFormat = NumberFormat.percentPattern();
    final scorePercentage = activity['score'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26), // 0.1 opacity
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getScoreColor(
                scorePercentage,
              ).withAlpha(26), // 0.1 opacity
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school,
              color: _getScoreColor(scorePercentage),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Score: ${scoreFormat.format(scorePercentage)} · +${activity['points']} points',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (activity.containsKey('timeSpent') &&
                    activity['timeSpent'] > 0)
                  Text(
                    'Time: ${_formatTime(activity['timeSpent'])}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Text(
            dateFormat.format(activity['date']),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26), // 0.1 opacity
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) {
      return Colors.green;
    } else if (score >= 0.6) {
      return Colors.blue;
    } else if (score >= 0.4) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getScoreMessage(double score) {
    if (score >= 0.8) {
      return 'Excellent!';
    } else if (score >= 0.6) {
      return 'Good job!';
    } else if (score >= 0.4) {
      return 'Keep practicing!';
    } else {
      return 'More study needed';
    }
  }
}

class BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final bool isEarned;

  const BadgeCard({super.key, required this.badge, required this.isEarned});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${badge.name}\n${badge.description}\nCriteria: ${badge.criteria}',
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      textStyle: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Opacity(
        opacity: isEarned ? 1.0 : 0.4,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: isEarned ? badge.color : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    isEarned
                        ? badge.color.withValues(alpha: 0.15)
                        : Colors.grey.shade200,
                child: Icon(
                  isEarned ? badge.icon : Icons.lock_outline,
                  size: 35,
                  color: isEarned ? badge.color : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isEarned ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
