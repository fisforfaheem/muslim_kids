import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:muslim_kids/models/badge_model.dart';
import 'package:muslim_kids/models/quiz_model.dart';
import 'package:muslim_kids/services/badge_service.dart';

class QuizCompletionScreen extends StatefulWidget {
  final QuizModel quiz;
  final int correctAnswers;
  final int totalQuestions;
  final int earnedPoints;
  final VoidCallback onContinue;

  const QuizCompletionScreen({
    super.key,
    required this.quiz,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.earnedPoints,
    required this.onContinue,
  });

  @override
  State<QuizCompletionScreen> createState() => _QuizCompletionScreenState();
}

class _QuizCompletionScreenState extends State<QuizCompletionScreen> {
  final BadgeService _badgeService = BadgeService();

  @override
  void initState() {
    super.initState();
    _checkAndAwardBadges();
  }

  Future<void> _checkAndAwardBadges() async {
    final newBadges = await _badgeService.checkAndAwardBadges();
    if (newBadges.isNotEmpty && mounted) {
      await showDialog(
        context: context,
        builder: (context) => BadgeUnlockedDialog(badges: newBadges),
      );
    }
  }

  double get score => widget.correctAnswers / widget.totalQuestions;

  String get resultMessage {
    if (score >= 0.9) {
      return 'Excellent! MashaAllah!';
    } else if (score >= 0.7) {
      return 'Great job!';
    } else if (score >= 0.5) {
      return 'Good effort!';
    } else {
      return 'Keep practicing!';
    }
  }

  String get feedbackMessage {
    if (score >= 0.9) {
      return 'Your knowledge of the Quran is impressive! Keep up the amazing work!';
    } else if (score >= 0.7) {
      return 'You have a good understanding of the Quran. Keep learning to improve even more!';
    } else if (score >= 0.5) {
      return 'You\'re making progress in your Quranic knowledge. Keep studying!';
    } else {
      return 'Don\'t worry, learning takes time. Review the topics and try again!';
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
            automaticallyImplyLeading: false,
            title: Text(
              'Quiz Results',
              style: GoogleFonts.kanit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Animation based on score
            Lottie.asset(
              'assets/success.json',
              width: 200,
              height: 200,
              repeat: true,
            ),

            // Quiz title
            Text(
              widget.quiz.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Result message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: score >= 0.7 ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(51), // 0.2 opacity
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    resultMessage,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                          score >= 0.7 ? Colors.green[800] : Colors.orange[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    feedbackMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          score >= 0.7 ? Colors.green[800] : Colors.orange[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Score
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatCard(
                  'Score',
                  '${widget.correctAnswers}/${widget.totalQuestions}',
                  Icons.check_circle,
                  Colors.blue,
                ),
                const SizedBox(width: 15),
                _buildStatCard(
                  'Percentage',
                  '${(score * 100).toInt()}%',
                  Icons.percent,
                  Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Rewards earned
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withAlpha(77), // 0.3 opacity
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Reward Points Earned',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${widget.earnedPoints}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'You earned ${(widget.earnedPoints / widget.quiz.rewardPoints * 100).toInt()}% of available points',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Points are added to your total rewards!',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Return to Quizzes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[200],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Try Another Quiz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Share button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Share functionality would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing feature coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Share your results'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(color: Colors.blue[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51), // 0.2 opacity
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class BadgeUnlockedDialog extends StatelessWidget {
  final List<BadgeModel> badges;
  const BadgeUnlockedDialog({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final badge = badges.first; // Show one badge at a time for simplicity
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [badge.color.withValues(alpha: 0.8), badge.color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Badge Unlocked!',
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(badge.icon, size: 50, color: badge.color),
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: badge.color,
              ),
              child: const Text('Awesome!'),
            )
          ],
        ),
      ),
    );
  }
}
