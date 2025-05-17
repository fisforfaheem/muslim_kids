import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_kids/services/quiz_service.dart';
import 'package:muslim_kids/Features/quizzes_page.dart';
import 'package:intl/intl.dart';

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
  List<Map<String, dynamic>> _quizResults = [];
  int _totalPoints = 0;
  int _completedQuizzes = 0;
  double _averageScore = 0;
  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProgress();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProgress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user quiz statistics and history
      final statistics = await _quizService.getUserQuizStatistics();
      final history = await _quizService.getUserQuizHistory();

      // Extract data from statistics
      final completedQuizzes = statistics['quizzesCompleted'] ?? 0;
      final points = statistics['totalPoints'] ?? 0;
      final avgScore = statistics['averageScore'] ?? 0.0;

      // Convert history to activity feed
      List<Map<String, dynamic>> activity = [];

      for (var result in history) {
        final score = result['score'] as int;
        final totalQuestions = result['totalQuestions'] as int;
        final quizTitle = result['quizTitle'] as String;
        final completedAt = result['completedAt'] as DateTime;
        final earnedPoints = (result['percentage'] as num? ?? 0) ~/ 10;

        double scorePercentage = score / totalQuestions;

        activity.add({
          'title': quizTitle,
          'date': completedAt,
          'score': scorePercentage,
          'points': earnedPoints,
          'type': 'quiz_completed',
        });
      }

      // Sort activity by date (newest first)
      activity.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

      setState(() {
        _quizResults = history;
        _totalPoints = points;
        _completedQuizzes = completedQuizzes;
        _averageScore =
            avgScore > 0 ? avgScore / 100 : 0; // Convert to 0-1 scale if needed
        _recentActivity =
            activity.take(5).toList(); // Take only 5 most recent activities
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress: $e');
      setState(() {
        _isLoading = false;
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
            // Key stats cards
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
                    _completedQuizzes.toString(),
                    Icons.school,
                    Colors.blue,
                  ),
                ),
              ],
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
                    color: Colors.grey.withOpacity(0.2),
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
    // Achievement definition - level, points required, icon, title, description, etc.
    final achievements = [
      {
        'title': 'Quiz Beginner',
        'description': 'Complete your first quiz',
        'icon': Icons.emoji_events,
        'color': Colors.blue,
        'unlocked': _completedQuizzes >= 1,
      },
      {
        'title': 'Quiz Explorer',
        'description': 'Complete 5 different quizzes',
        'icon': Icons.explore,
        'color': Colors.green,
        'unlocked': _completedQuizzes >= 5,
      },
      {
        'title': 'Quiz Master',
        'description': 'Complete 10 different quizzes',
        'icon': Icons.school,
        'color': Colors.purple,
        'unlocked': _completedQuizzes >= 10,
      },
      {
        'title': 'Perfect Score',
        'description': 'Get 100% on any quiz',
        'icon': Icons.star,
        'color': Colors.amber,
        'unlocked': _quizResults.any(
          (result) => result['score'] == result['totalQuestions'],
        ),
      },
      {
        'title': 'Knowledge Seeker',
        'description': 'Earn at least 50 reward points',
        'icon': Icons.lightbulb,
        'color': Colors.orange,
        'unlocked': _totalPoints >= 50,
      },
      {
        'title': 'Quran Scholar',
        'description': 'Earn at least 100 reward points',
        'icon': Icons.auto_awesome,
        'color': Colors.indigo,
        'unlocked': _totalPoints >= 100,
      },
      {
        'title': 'Dedication',
        'description': 'Complete quizzes from 3 different categories',
        'icon': Icons.category,
        'color': Colors.pink,
        'unlocked': _quizResults.isNotEmpty && _quizResults.length >= 3,
      },
      {
        'title': 'Consistent Learner',
        'description': 'Complete at least 5 quizzes with 80% or higher score',
        'icon': Icons.timeline,
        'color': Colors.teal,
        'unlocked':
            _quizResults
                .where(
                  (r) =>
                      (r['score'] as int) / (r['totalQuestions'] as int) >= 0.8,
                )
                .length >=
            5,
      },
    ];

    final unlockedAchievements =
        achievements.where((a) => a['unlocked'] as bool).toList();
    final lockedAchievements =
        achievements.where((a) => !(a['unlocked'] as bool)).toList();

    return RefreshIndicator(
      onRefresh: _loadUserProgress,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.pink.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Your Achievements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${unlockedAchievements.length}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        ' / ${achievements.length}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: unlockedAchievements.length / achievements.length,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Keep going to unlock all achievements!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Unlocked Achievements
            if (unlockedAchievements.isNotEmpty) ...[
              Text(
                'Unlocked Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              ...unlockedAchievements.map(
                (achievement) => _buildAchievementItem(achievement, true),
              ),
              const SizedBox(height: 24),
            ],

            // Locked Achievements
            if (lockedAchievements.isNotEmpty) ...[
              Text(
                'Achievements to Unlock',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              ...lockedAchievements.map(
                (achievement) => _buildAchievementItem(achievement, false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
            color: Colors.grey.withOpacity(0.1),
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
              color: _getScoreColor(scorePercentage).withOpacity(0.1),
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

  Widget _buildAchievementItem(
    Map<String, dynamic> achievement,
    bool unlocked,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              unlocked
                  ? (achievement['color'] as Color).withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  unlocked
                      ? (achievement['color'] as Color).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement['icon'] as IconData,
              color: unlocked ? achievement['color'] as Color : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: unlocked ? Colors.black87 : Colors.grey,
                  ),
                ),
                Text(
                  achievement['description'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: unlocked ? Colors.black54 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.check_circle : Icons.lock,
            color: unlocked ? Colors.green : Colors.grey,
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
            color: Colors.grey.withOpacity(0.1),
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
