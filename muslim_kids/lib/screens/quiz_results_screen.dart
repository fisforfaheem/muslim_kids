import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:muslim_kids/models/quiz_model.dart';
import 'package:muslim_kids/services/quiz_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizResultsScreen extends StatefulWidget {
  const QuizResultsScreen({super.key});

  @override
  QuizResultsScreenState createState() => QuizResultsScreenState();
}

class QuizResultsScreenState extends State<QuizResultsScreen> {
  final QuizService _quizService = QuizService();
  bool _isLoading = true;
  List<QuizResult> _results = [];
  Map<String, QuizModel> _quizzes = {};

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resultsData = await _quizService.getUserQuizHistory();

      // Convert to QuizResult objects
      List<QuizResult> convertedResults = resultsData.map((data) {
        return QuizResult(
          quizId: data['quizId'] ?? '',
          userId:
              data['userId'] ?? FirebaseAuth.instance.currentUser?.uid ?? '',
          score: data['score'] ?? 0,
          totalQuestions: data['totalQuestions'] ?? 0,
          earnedPoints: data['earnedPoints'] ?? 0,
          completedAt: data['completedAt'] is DateTime
              ? data['completedAt']
              : DateTime.now(),
        );
      }).toList();

      // Load quiz details for each result
      Map<String, QuizModel> quizzes = {};
      for (var result in convertedResults) {
        if (!quizzes.containsKey(result.quizId)) {
          final quizData = await _quizService.getQuizById(result.quizId);
          if (quizData != null) {
            // Convert Map to QuizModel
            List<QuizQuestion> questions = [];
            if (quizData['questions'] != null) {
              for (var questionData in quizData['questions']) {
                questions.add(QuizQuestion.fromMap(questionData));
              }
            }

            quizzes[result.quizId] = QuizModel(
              id: quizData['id'] ?? '',
              title: quizData['title'] ?? '',
              description: quizData['description'] ?? '',
              difficulty: quizData['difficulty'] ?? 'Easy',
              rewardPoints: quizData['rewardPoints'] ?? 10,
              questions: questions,
              category: quizData['category'] ?? 'General',
              imageUrl: quizData['imageUrl'] ?? 'assets/quizzes.jpg',
            );
          }
        }
      }

      setState(() {
        _results = convertedResults;
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading results: $e');
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Quiz History',
              style: GoogleFonts.kanit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? _buildEmptyState()
              : _buildResultsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No Quiz History Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Complete some quizzes to see your history here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[200],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Go Take a Quiz',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return RefreshIndicator(
      onRefresh: _loadResults,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          final quiz = _quizzes[result.quizId];
          final score = result.score / result.totalQuestions;
          final formattedDate =
              DateFormat('MMM d, yyyy • h:mm a').format(result.completedAt);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
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
                // Header with date and score
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getScoreColor(score),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(score * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quiz details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quiz title
                      Text(
                        quiz?.title ?? 'Unknown Quiz',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Score and points
                      Row(
                        children: [
                          Expanded(
                            child: _buildResultInfo(
                              'Score',
                              '${result.score}/${result.totalQuestions}',
                              Icons.check_circle,
                            ),
                          ),
                          Expanded(
                            child: _buildResultInfo(
                              'Points Earned',
                              '${result.earnedPoints} pts',
                              Icons.star,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Difficulty and category
                      if (quiz != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildResultInfo(
                                'Difficulty',
                                quiz.difficulty,
                                Icons.signal_cellular_alt,
                              ),
                            ),
                            Expanded(
                              child: _buildResultInfo(
                                'Category',
                                quiz.category,
                                Icons.category,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultInfo(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
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
}
