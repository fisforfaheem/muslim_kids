import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_kids/models/quiz_model.dart';
import 'package:muslim_kids/services/quiz_service.dart';
import 'package:muslim_kids/screens/quiz_detail_screen.dart';
import 'package:muslim_kids/screens/quiz_results_screen.dart';
import 'package:lottie/lottie.dart';

class QuizzesPage extends StatefulWidget {
  const QuizzesPage({super.key});

  @override
  QuizzesPageState createState() => QuizzesPageState();
}

class QuizzesPageState extends State<QuizzesPage>
    with SingleTickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  bool _isLoading = true;
  List<QuizModel> _quizzes = [];
  List<String> _completedQuizIds = [];
  int _userPoints = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quizzes = await _quizService.getQuizzes();
      final completedQuizIds = await _quizService.getCompletedQuizIds();
      final userPoints = await _quizService.getUserPoints();

      setState(() {
        // Convert Map data to QuizModel objects
        _quizzes =
            quizzes
                .map(
                  (quizData) => QuizModel(
                    id: quizData['id'] ?? '',
                    title: quizData['title'] ?? '',
                    description: quizData['description'] ?? '',
                    difficulty: quizData['difficulty'] ?? 'Easy',
                    rewardPoints: quizData['rewardPoints'] ?? 10,
                    questions:
                        (quizData['questions'] as List<dynamic>? ?? [])
                            .map(
                              (q) => QuizQuestion(
                                question: q['question'] ?? '',
                                options:
                                    (q['options'] as List<dynamic>? ?? [])
                                        .map((o) => o.toString())
                                        .toList(),
                                correctOptionIndex:
                                    q['correctOptionIndex'] ?? 0,
                                explanation: q['explanation'],
                              ),
                            )
                            .toList(),
                    category: quizData['category'] ?? 'General',
                    imageUrl: quizData['imageUrl'] ?? 'assets/quizzes.jpg',
                  ),
                )
                .toList();
        _completedQuizIds = completedQuizIds;
        _userPoints = userPoints;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
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
        preferredSize: const Size.fromHeight(120),
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Quranic Quizzes',
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
              tabs: const [
                Tab(text: 'ALL'),
                Tab(text: 'COMPLETED'),
                Tab(text: 'REWARDS'),
              ],
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildQuizzesList(false), // All quizzes
                  _buildQuizzesList(true), // Completed quizzes
                  _buildRewardsTab(), // Rewards tab
                ],
              ),
    );
  }

  Widget _buildQuizzesList(bool completedOnly) {
    List<QuizModel> filteredQuizzes =
        completedOnly
            ? _quizzes
                .where((quiz) => _completedQuizIds.contains(quiz.id))
                .toList()
            : _quizzes;

    if (filteredQuizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/success.json',
              width: 200,
              height: 200,
              repeat: true,
            ),
            Text(
              completedOnly
                  ? 'No completed quizzes yet!'
                  : 'No quizzes available!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              completedOnly
                  ? 'Complete some quizzes to see them here.'
                  : 'Check back later for new quizzes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredQuizzes.length,
        itemBuilder: (context, index) {
          final quiz = filteredQuizzes[index];
          final isCompleted = _completedQuizIds.contains(quiz.id);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizDetailScreen(quizId: quiz.id),
                ),
              ).then((_) => _loadData()); // Refresh data when returning
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(77), // 0.3 opacity
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                        child: Image.asset(
                          quiz.imageUrl,
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isCompleted ? 'Completed' : quiz.difficulty,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                quiz.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${quiz.rewardPoints} points',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quiz.description,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoChip(
                              Icons.format_list_numbered,
                              '${quiz.questions.length} Questions',
                              Colors.indigo.withAlpha(179), // 0.7 opacity
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              Icons.category,
                              quiz.category,
                              Colors.purple.withAlpha(179), // 0.7 opacity
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // 0.1 opacity
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)), // 0.3 opacity
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Points Display
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFAB40), Color(0xFFFF6F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withAlpha(102), // 0.4 opacity
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Your Total Reward Points',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      size: 40,
                      color: Colors.amber[100],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _userPoints.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Complete more quizzes to earn points!',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Achievement section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Achievements',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildAchievementsList(),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // View Full Results Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuizResultsScreen(),
                  ),
                ).then((_) => _loadData()); // Refresh data when returning
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[200],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'View Full Results History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Add bottom padding to prevent overflow
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAchievementsList() {
    // Define achievement levels based on completed quizzes
    final achievements = [
      {
        'title': 'Quiz Beginner',
        'description': 'Complete your first quiz',
        'icon': Icons.emoji_events,
        'color': Colors.blue,
        'unlocked': _completedQuizIds.isNotEmpty,
      },
      {
        'title': 'Quiz Explorer',
        'description': 'Complete 5 different quizzes',
        'icon': Icons.explore,
        'color': Colors.green,
        'unlocked': _completedQuizIds.length >= 5,
      },
      {
        'title': 'Quiz Master',
        'description': 'Complete 10 different quizzes',
        'icon': Icons.school,
        'color': Colors.purple,
        'unlocked': _completedQuizIds.length >= 10,
      },
      {
        'title': 'Quran Scholar',
        'description': 'Earn at least 100 reward points',
        'icon': Icons.auto_awesome,
        'color': Colors.orange,
        'unlocked': _userPoints >= 100,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final unlocked = achievement['unlocked'] as bool;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  unlocked
                      ? (achievement['color'] as Color).withAlpha(
                        128,
                      ) // 0.5 opacity
                      : Colors.grey.withAlpha(77), // 0.3 opacity
            ),
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
                  color:
                      unlocked
                          ? (achievement['color'] as Color).withAlpha(
                            51,
                          ) // 0.2 opacity
                          : Colors.grey.withAlpha(26), // 0.1 opacity
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement['icon'] as IconData,
                  color: unlocked ? achievement['color'] as Color : Colors.grey,
                  size: 24,
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
                size: 28,
              ),
            ],
          ),
        );
      },
    );
  }
}
