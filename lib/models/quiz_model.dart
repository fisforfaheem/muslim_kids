import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final int rewardPoints;
  final List<QuizQuestion> questions;
  final String category;
  final String imageUrl;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.rewardPoints,
    required this.questions,
    required this.category,
    this.imageUrl = 'assets/quizzes.jpg',
  });

  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<QuizQuestion> questions = [];
    if (data['questions'] != null) {
      for (var questionData in data['questions']) {
        questions.add(QuizQuestion.fromMap(questionData));
      }
    }

    return QuizModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      difficulty: data['difficulty'] ?? 'Easy',
      rewardPoints: data['rewardPoints'] ?? 10,
      questions: questions,
      category: data['category'] ?? 'General',
      imageUrl: data['imageUrl'] ?? 'assets/quizzes.jpg',
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> data) {
    List<String> options = [];
    if (data['options'] != null) {
      for (var option in data['options']) {
        options.add(option.toString());
      }
    }

    return QuizQuestion(
      question: data['question'] ?? '',
      options: options,
      correctOptionIndex: data['correctOptionIndex'] ?? 0,
      explanation: data['explanation'],
    );
  }
}

class QuizResult {
  final String quizId;
  final String userId;
  final int score;
  final int totalQuestions;
  final int earnedPoints;
  final DateTime completedAt;

  QuizResult({
    required this.quizId,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.earnedPoints,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'userId': userId,
      'score': score,
      'totalQuestions': totalQuestions,
      'earnedPoints': earnedPoints,
      'completedAt': completedAt,
    };
  }

  factory QuizResult.fromMap(Map<String, dynamic> data) {
    return QuizResult(
      quizId: data['quizId'] ?? '',
      userId: data['userId'] ?? '',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      earnedPoints: data['earnedPoints'] ?? 0,
      completedAt: (data['completedAt'] as Timestamp).toDate(),
    );
  }
}
