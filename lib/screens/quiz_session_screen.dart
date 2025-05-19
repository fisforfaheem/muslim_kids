import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_kids/models/quiz_model.dart';
import 'package:muslim_kids/services/quiz_service.dart';
import 'package:muslim_kids/screens/quiz_completion_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math' as math;

class QuizSessionScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizSessionScreen({super.key, required this.quiz});

  @override
  QuizSessionScreenState createState() => QuizSessionScreenState();
}

class QuizSessionScreenState extends State<QuizSessionScreen> {
  final QuizService _quizService = QuizService();
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswerRevealed = false;
  List<int> _userAnswers = [];
  bool _isQuizCompleted = false;

  // Time tracking variables
  int _quizTimeInSeconds = 0;
  Timer? _quizTimer;

  @override
  void initState() {
    super.initState();
    // Initialize user answers list with nulls (no answer selected yet)
    _userAnswers = List.filled(widget.quiz.questions.length, -1);

    // Start the quiz timer
    _startQuizTimer();
  }

  @override
  void dispose() {
    // Make sure to cancel the timer when the screen is disposed
    _quizTimer?.cancel();
    super.dispose();
  }

  // Start the timer to track quiz duration
  void _startQuizTimer() {
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _quizTimeInSeconds++;
      });
    });
  }

  // Stop the timer when quiz is completed
  void _stopQuizTimer() {
    _quizTimer?.cancel();
    _quizTimer = null;
  }

  QuizQuestion get _currentQuestion =>
      widget.quiz.questions[_currentQuestionIndex];
  bool get _isLastQuestion =>
      _currentQuestionIndex == widget.quiz.questions.length - 1;

  void _selectAnswer(int index) {
    if (_isAnswerRevealed) {
      return; // Don't allow changing answer after revealing
    }

    setState(() {
      _selectedAnswerIndex = index;
    });
  }

  void _revealAnswer() {
    if (_selectedAnswerIndex == null) return; // Must select an answer first

    setState(() {
      _isAnswerRevealed = true;
      _userAnswers[_currentQuestionIndex] = _selectedAnswerIndex!;
    });
  }

  void _moveToNextQuestion() {
    if (_isLastQuestion) {
      _finishQuiz();
      return;
    }

    setState(() {
      _currentQuestionIndex++;
      _selectedAnswerIndex = null;
      _isAnswerRevealed = false;
    });
  }

  // Error state for quiz submission
  bool _hasSubmissionError = false;
  String _errorMessage = '';

  Future<void> _finishQuiz() async {
    if (_isQuizCompleted) return;

    // Stop the timer when quiz is completed
    _stopQuizTimer();

    setState(() {
      _isQuizCompleted = true;
      _hasSubmissionError = false;
      _errorMessage = '';
    });

    // Calculate score
    int correctAnswers = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_userAnswers[i] == widget.quiz.questions[i].correctOptionIndex) {
        correctAnswers++;
      }
    }

    // Calculate points earned - scale based on percentage correct
    final percentageCorrect = correctAnswers / widget.quiz.questions.length;
    final earnedPoints = (widget.quiz.rewardPoints * percentageCorrect).round();

    // Submit result to Firestore
    bool submissionSuccess = false;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        submissionSuccess = await _quizService.submitQuizResult(
          quizId: widget.quiz.id,
          quizTitle: widget.quiz.title,
          score: correctAnswers,
          totalQuestions: widget.quiz.questions.length,
          timeSpentInSeconds: _quizTimeInSeconds, // Now using the tracked time
        );

        if (!submissionSuccess && mounted) {
          setState(() {
            _hasSubmissionError = true;
            _errorMessage = 'Failed to save your quiz results. Tap to retry.';
          });
          return; // Don't navigate away if submission failed
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasSubmissionError = true;
            _errorMessage =
                'Error: ${e.toString().substring(0, math.min(e.toString().length, 50))}...';
          });
          return; // Don't navigate away if there was an error
        }
      }
    }

    // Navigate to completion screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => QuizCompletionScreen(
                quiz: widget.quiz,
                correctAnswers: correctAnswers,
                totalQuestions: widget.quiz.questions.length,
                earnedPoints: earnedPoints,
              ),
        ),
      );
    }
  }

  // Retry submission if it failed
  Future<void> _retrySubmission() async {
    setState(() {
      _hasSubmissionError = false;
      _errorMessage = '';
    });

    await _finishQuiz();
  }

  // Build the completion state UI (loading or error)
  Widget _buildCompletionState() {
    if (_hasSubmissionError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              Text(
                'Submission Error',
                style: GoogleFonts.kanit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _retrySubmission,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Submission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Show loading state
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Saving your results...',
              style: GoogleFonts.kanit(fontSize: 18),
            ),
          ],
        ),
      );
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
              icon: const Icon(Icons.close, size: 30),
              onPressed: () => _showExitConfirmation(),
            ),
            title: Text(
              widget.quiz.title,
              style: GoogleFonts.kanit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(120),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.quiz, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body:
          _isQuizCompleted
              ? _buildCompletionState()
              : Column(
                children: [
                  // Progress bar
                  LinearProgressIndicator(
                    value:
                        (_currentQuestionIndex + 1) /
                        widget.quiz.questions.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.pink[200]!,
                    ),
                    minHeight: 8,
                  ),

                  // Question and options
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question text
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withAlpha(
                                    51,
                                  ), // 0.2 opacity
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
                                  'Question ${_currentQuestionIndex + 1}:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink[300],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _currentQuestion.question,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Answer options
                          ...List.generate(
                            _currentQuestion.options.length,
                            (index) => _buildAnswerOption(index),
                          ),

                          // Explanation (shown after answer is revealed)
                          if (_isAnswerRevealed &&
                              _currentQuestion.explanation != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(26), // 0.1 opacity
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue.withAlpha(
                                    77,
                                  ), // 0.3 opacity
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Explanation:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _currentQuestion.explanation!,
                                    style: TextStyle(color: Colors.blue[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Bottom action buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(77), // 0.3 opacity
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child:
                        _isAnswerRevealed
                            ? SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _moveToNextQuestion,
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
                                  _isLastQuestion
                                      ? 'Finish Quiz'
                                      : 'Next Question',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _selectedAnswerIndex != null
                                        ? _revealAnswer
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Check Answer',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildAnswerOption(int index) {
    final option = _currentQuestion.options[index];
    final isSelected = _selectedAnswerIndex == index;
    final isCorrect = index == _currentQuestion.correctOptionIndex;

    // Define colors based on selection and reveal state
    Color backgroundColor;
    Color borderColor;
    Color textColor = Colors.black;

    if (_isAnswerRevealed) {
      if (isCorrect) {
        backgroundColor = Colors.green.withAlpha(51); // 0.2 opacity
        borderColor = Colors.green;
        textColor = Colors.green[800]!;
      } else if (isSelected) {
        backgroundColor = Colors.red.withAlpha(51); // 0.2 opacity
        borderColor = Colors.red;
        textColor = Colors.red[800]!;
      } else {
        backgroundColor = Colors.white;
        borderColor = Colors.grey.withAlpha(77); // 0.3 opacity
      }
    } else {
      backgroundColor =
          isSelected ? Colors.blue.withAlpha(26) : Colors.white; // 0.1 opacity
      borderColor =
          isSelected
              ? Colors.blue.withAlpha(77) // 0.3 opacity
              : Colors.grey.withAlpha(77); // 0.3 opacity
    }

    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.blue
                        : Colors.grey.withAlpha(51), // 0.2 opacity
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D, etc.
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (_isAnswerRevealed) ...[
              Icon(
                isCorrect
                    ? Icons.check_circle
                    : (isSelected ? Icons.cancel : null),
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    // Stop timer while dialog is shown to prevent inaccurate time tracking
    final wasTimerActive = _quizTimer != null;
    if (wasTimerActive) {
      _quizTimer?.cancel();
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder:
          (context) => AlertDialog(
            title: const Text('Exit Quiz?'),
            content: const Text(
              'Your progress will be lost if you exit now. Are you sure you want to exit?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Resume timer if it was active
                  if (wasTimerActive && mounted) {
                    _startQuizTimer();
                  }
                },
                child: const Text('Continue Quiz'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Exit quiz
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Exit Quiz'),
              ),
            ],
          ),
    );
  }
}
