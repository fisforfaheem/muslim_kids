import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_kids/models/quiz_model.dart';
import 'package:muslim_kids/services/quiz_service.dart';
import 'package:muslim_kids/screens/quiz_session_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class QuizDetailScreen extends StatefulWidget {
  final String quizId;

  const QuizDetailScreen({super.key, required this.quizId});

  @override
  QuizDetailScreenState createState() => QuizDetailScreenState();
}

class QuizDetailScreenState extends State<QuizDetailScreen> {
  final QuizService _quizService = QuizService();
  bool _isLoading = true;
  QuizModel? _quiz;
  bool _hasCompletedQuiz = false;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quizData = await _quizService.getQuizById(widget.quizId);
      final completedQuizIds = await _quizService.getCompletedQuizIds();

      // List of available quiz images
      final List<String> quizImages = [
        'assets/11.jpg',
        'assets/22.jpg',
        'assets/33.jpg',
        'assets/44.jpg',
        'assets/55.jpg',
        'assets/66.jpg',
        'assets/77.jpg',
        'assets/88.jpg',
        'assets/99.jpg',
      ];

      setState(() {
        // Convert Map data to QuizModel object if quiz data exists
        if (quizData != null) {
          List<QuizQuestion> questions = [];
          if (quizData['questions'] != null) {
            for (var questionData in quizData['questions']) {
              questions.add(QuizQuestion.fromMap(questionData));
            }
          }

          // Use the imageUrl from Firestore if it exists and is not empty
          // Otherwise, use a numbered image based on the quiz ID's hashcode
          final String imageUrl;
          if (quizData['imageUrl'] != null &&
              quizData['imageUrl'].toString().isNotEmpty) {
            imageUrl = quizData['imageUrl'];
          } else {
            // Use the quiz ID's hashcode to determine which image to use
            final int hashCode = widget.quizId.hashCode.abs();
            final int imageIndex = hashCode % quizImages.length;
            imageUrl = quizImages[imageIndex];
          }

          _quiz = QuizModel(
            id: quizData['id'] ?? '',
            title: quizData['title'] ?? '',
            description: quizData['description'] ?? '',
            difficulty: quizData['difficulty'] ?? 'Easy',
            rewardPoints: quizData['rewardPoints'] ?? 10,
            questions: questions,
            category: quizData['category'] ?? 'General',
            imageUrl: imageUrl,
          );
        } else {
          _quiz = null;
        }

        _hasCompletedQuiz = completedQuizIds.contains(widget.quizId);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading quiz data: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      Fluttertoast.showToast(
        msg: 'Failed to load quiz. Please try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _startQuiz() {
    if (_quiz == null) return;

    if (FirebaseAuth.instance.currentUser == null) {
      Fluttertoast.showToast(
        msg: 'You need to be logged in to take a quiz.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Validate quiz data before starting
    if (_quiz!.questions.isEmpty) {
      _showErrorDialog('This quiz has no questions. Please try another quiz.');
      return;
    }

    // Check if any question has invalid data
    bool hasInvalidQuestions = false;
    String errorMessage = '';

    for (int i = 0; i < _quiz!.questions.length; i++) {
      final question = _quiz!.questions[i];

      // Check if question text is empty
      if (question.question.trim().isEmpty) {
        hasInvalidQuestions = true;
        errorMessage = 'Question ${i + 1} has no text.';
        break;
      }

      // Check if there are enough options
      if (question.options.length < 2) {
        hasInvalidQuestions = true;
        errorMessage = 'Question ${i + 1} has fewer than 2 options.';
        break;
      }

      // Check if correct option index is valid
      if (question.correctOptionIndex < 0 ||
          question.correctOptionIndex >= question.options.length) {
        hasInvalidQuestions = true;
        errorMessage = 'Question ${i + 1} has an invalid correct answer.';
        break;
      }
    }

    if (hasInvalidQuestions) {
      _showErrorDialog(
        'Quiz data error: $errorMessage Please try another quiz.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuizSessionScreen(quiz: _quiz!)),
    ).then((_) => _loadQuizData()); // Refresh when coming back
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Quiz Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
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
              'Quiz Details',
              style: GoogleFonts.kanit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _quiz == null
              ? const Center(child: Text('Quiz not found'))
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quiz Image
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(_quiz!.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and difficulty
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _quiz!.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(_quiz!.difficulty),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _quiz!.difficulty,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Description
                          Text(
                            _quiz!.description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Quiz Info
                          _buildInfoTile(
                            'Questions',
                            '${_quiz!.questions.length} questions to answer',
                            Icons.question_answer,
                          ),

                          _buildInfoTile(
                            'Category',
                            _quiz!.category,
                            Icons.category,
                          ),

                          _buildInfoTile(
                            'Reward Points',
                            '${_quiz!.rewardPoints} points to earn',
                            Icons.star,
                          ),

                          _buildInfoTile(
                            'Status',
                            _hasCompletedQuiz
                                ? 'Completed'
                                : 'Not completed yet',
                            _hasCompletedQuiz
                                ? Icons.check_circle
                                : Icons.pending,
                            iconColor:
                                _hasCompletedQuiz
                                    ? Colors.green
                                    : Colors.orange,
                          ),

                          const SizedBox(height: 30),

                          // Start Quiz Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _startQuiz,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink[200],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                _hasCompletedQuiz
                                    ? 'Retake Quiz'
                                    : 'Start Quiz',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          if (_hasCompletedQuiz) ...[
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                'You have already completed this quiz. Retaking it will not earn additional points.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoTile(
    String title,
    String subtitle,
    IconData icon, {
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
              color: (iconColor ?? Colors.blue).withAlpha(26), // 0.1 opacity
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? Colors.blue, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
