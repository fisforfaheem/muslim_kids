import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:muslim_kids/models/quiz_model.dart';

class QuizCompletionScreen extends StatelessWidget {
  final QuizModel quiz;
  final int correctAnswers;
  final int totalQuestions;
  final int earnedPoints;

  const QuizCompletionScreen({
    super.key,
    required this.quiz,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.earnedPoints,
  });

  double get score => correctAnswers / totalQuestions;

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
              quiz.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
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
                    color: Colors.grey.withOpacity(0.2),
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
                  '$correctAnswers/$totalQuestions',
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
            _buildStatCard(
              'Points Earned',
              '$earnedPoints points',
              Icons.workspace_premium,
              Colors.amber,
              fullWidth: true,
            ),

            const SizedBox(height: 30),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
                        content: Text('Sharing feature coming soon!')),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
