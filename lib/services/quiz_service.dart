import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all available quizzes with improved error handling
  Future<List<Map<String, dynamic>>> getQuizzes() async {
    try {
      // Add timeout to prevent hanging requests
      final snapshot = await Future.any([
        _firestore.collection('quizzes').get(),
        Future.delayed(
          const Duration(seconds: 10),
          () => throw TimeoutException('Quiz fetch request timed out'),
        ),
      ]);

      debugPrint('Successfully fetched ${snapshot.docs.length} quizzes');

      if (snapshot.docs.isEmpty) {
        debugPrint('WARNING: No quizzes found in the database!');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      debugPrint('Error fetching quizzes: $e');
      // Log more details about the error
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }
      return [];
    }
  }

  // Get a specific quiz by ID with improved error handling
  Future<Map<String, dynamic>?> getQuizById(String quizId) async {
    try {
      // Add timeout to prevent hanging requests
      final doc = await Future.any([
        _firestore.collection('quizzes').doc(quizId).get(),
        Future.delayed(
          const Duration(seconds: 10),
          () => throw TimeoutException('Quiz fetch request timed out'),
        ),
      ]);

      if (doc.exists) {
        debugPrint('Successfully fetched quiz with ID: $quizId');
        return {'id': doc.id, ...doc.data()!};
      }

      debugPrint('WARNING: Quiz with ID $quizId not found!');
      return null;
    } catch (e) {
      debugPrint('Error fetching quiz $quizId: $e');
      // Log more details about the error
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }
      return null;
    }
  }

  // Store failed quiz submission for later retry
  Future<void> _storeFailedSubmission(
    String quizId,
    String quizTitle,
    int score,
    int totalQuestions,
    int timeSpentInSeconds,
  ) async {
    try {
      // This would ideally use a local database like Hive or SQLite
      // For now, we'll use a simple print statement
      print(
        'Storing failed submission for later: Quiz $quizId, Score: $score/$totalQuestions',
      );
      // In a real implementation, you would store this data locally
    } catch (e) {
      print('Error storing failed submission: $e');
    }
  }

  // Submit quiz result with retry logic
  Future<bool> submitQuizResult({
    required String quizId,
    required String quizTitle,
    required int score,
    required int totalQuestions,
    required int timeSpentInSeconds,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final user = _auth.currentUser;
        if (user == null) return false;

        final percentage = (score / totalQuestions) * 100;
        final timestamp = Timestamp.now();

        // Calculate points earned based on percentage
        int basePoints = quizTitle.contains('Quranic') ? 20 : 10;
        final pointsEarned = ((percentage / 100) * basePoints).round();

        // Add result to user's quiz history
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('quizResults')
            .add({
              'quizId': quizId,
              'quizTitle': quizTitle,
              'score': score,
              'totalQuestions': totalQuestions,
              'percentage': percentage,
              'timeSpentInSeconds': timeSpentInSeconds,
              'earnedPoints': pointsEarned,
              'completedAt': timestamp,
            });

        // Update user's progress and statistics
        final userRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userRef.get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Update quiz stats
          int quizzesCompleted = userData['quizzesCompleted'] ?? 0;
          int totalScore = userData['totalQuizScore'] ?? 0;
          int totalQuizzes = userData['totalQuizzes'] ?? 0;
          List<dynamic> completedQuizIds = userData['completedQuizIds'] ?? [];

          // Check if this is the first time completing this quiz
          if (!completedQuizIds.contains(quizId)) {
            completedQuizIds.add(quizId);
          }

          // Update points only if score is better than previous attempts
          List<dynamic> quizScores = userData['quizScores'] ?? [];
          bool isNewScore = true;

          for (int i = 0; i < quizScores.length; i++) {
            if (quizScores[i]['quizId'] == quizId) {
              isNewScore = false;
              // Update if new score is better
              if (quizScores[i]['score'] < score) {
                quizScores[i]['score'] = score;
                quizScores[i]['percentage'] = percentage;
                quizScores[i]['completedAt'] = timestamp;
              }
              break;
            }
          }

          if (isNewScore) {
            quizScores.add({
              'quizId': quizId,
              'quizTitle': quizTitle,
              'score': score,
              'percentage': percentage,
              'completedAt': timestamp,
            });
          }

          int currentPoints = userData['points'] ?? 0;

          // Check for achievements based on quiz completion
          List<dynamic> achievements = userData['achievements'] ?? [];

          // First quiz achievement - Quiz Beginner
          if (completedQuizIds.isEmpty) {
            achievements.add({
              'title': 'Quiz Beginner',
              'description': 'Complete your first quiz',
              'earnedAt': timestamp,
              'icon': 'emoji_events',
            });
          }

          // 5 quizzes achievement - Quiz Explorer
          if (completedQuizIds.length == 4) {
            achievements.add({
              'title': 'Quiz Explorer',
              'description': 'Complete 5 different quizzes',
              'earnedAt': timestamp,
              'icon': 'explore',
            });
          }

          // 10 quizzes achievement - Quiz Master
          if (completedQuizIds.length == 9) {
            achievements.add({
              'title': 'Quiz Master',
              'description': 'Complete 10 different quizzes',
              'earnedAt': timestamp,
              'icon': 'school',
            });
          }

          // 100 points achievement - Quran Scholar
          if (currentPoints < 100 && (currentPoints + pointsEarned) >= 100) {
            achievements.add({
              'title': 'Quran Scholar',
              'description': 'Earn at least 100 reward points',
              'earnedAt': timestamp,
              'icon': 'auto_awesome',
            });
          }

          // Perfect score achievement
          if (percentage == 100) {
            achievements.add({
              'title': 'Perfect Score',
              'description': 'Earned a perfect score on a quiz!',
              'earnedAt': timestamp,
              'icon': 'star',
            });
          }

          // Update user document
          await userRef.update({
            'quizzesCompleted': quizzesCompleted + 1,
            'totalQuizScore': totalScore + score,
            'totalQuizzes': totalQuizzes + 1,
            'completedQuizIds': completedQuizIds,
            'quizScores': quizScores,
            'points': currentPoints + pointsEarned,
            'achievements': achievements,
            'lastQuizCompletedAt': timestamp,
          });
        }

        return true;
      } catch (e) {
        retryCount++;
        print('Error submitting quiz result (attempt $retryCount): $e');

        if (retryCount >= maxRetries) {
          // Store locally for later submission
          await _storeFailedSubmission(
            quizId,
            quizTitle,
            score,
            totalQuestions,
            timeSpentInSeconds,
          );
          return false;
        }

        // Wait before retry with exponential backoff
        await Future.delayed(Duration(seconds: retryCount));
      }
    }

    return false;
  }

  // Get user's quiz history
  Future<List<Map<String, dynamic>>> getUserQuizHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('quizResults')
              .orderBy('completedAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'completedAt': data['completedAt'].toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error fetching user quiz history: $e');
      return [];
    }
  }

  // Get user's quiz statistics with improved accuracy
  Future<Map<String, dynamic>> getUserQuizStatistics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'quizzesCompleted': 0,
          'averageScore': 0.0,
          'totalPoints': 0,
          'achievements': [],
          'recentResults': [],
          'uniqueQuizzes': 0,
          'bestScore': 0.0,
          'totalTimeSpent': 0,
        };
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return {
          'quizzesCompleted': 0,
          'averageScore': 0.0,
          'totalPoints': 0,
          'achievements': [],
          'recentResults': [],
          'uniqueQuizzes': 0,
          'bestScore': 0.0,
          'totalTimeSpent': 0,
        };
      }

      final userData = userDoc.data()!;

      // Get ALL quiz results for more accurate statistics
      final allResultsSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('quizResults')
              .orderBy('completedAt', descending: true)
              .get();

      final allResults =
          allResultsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
              'completedAt': data['completedAt'].toDate(),
            };
          }).toList();

      // Get recent quiz results (just the most recent 5)
      final recentResults = allResults.take(5).toList();

      // Calculate statistics directly from quiz results for accuracy
      int quizzesCompleted = allResults.length;

      // Calculate unique quizzes completed
      Set<String> uniqueQuizIds = {};
      for (var result in allResults) {
        uniqueQuizIds.add(result['quizId'] as String);
      }
      int uniqueQuizzes = uniqueQuizIds.length;

      // Calculate total score and average more accurately
      double totalPercentage = 0.0;
      double bestScore = 0.0;
      int totalTimeSpent = 0;

      // Group results by quiz ID to find best scores
      Map<String, Map<String, dynamic>> bestScoresByQuiz = {};

      for (var result in allResults) {
        final quizId = result['quizId'] as String;
        final percentage = result['percentage'] as num;
        final timeSpent = result['timeSpentInSeconds'] as int? ?? 0;

        totalTimeSpent += timeSpent;

        // Track best score for each quiz
        if (!bestScoresByQuiz.containsKey(quizId) ||
            bestScoresByQuiz[quizId]!['percentage']! < percentage) {
          bestScoresByQuiz[quizId] = {
            'percentage': percentage,
            'score': result['score'],
            'totalQuestions': result['totalQuestions'],
          };
        }
      }

      // Calculate average based on best scores for each quiz
      for (var entry in bestScoresByQuiz.entries) {
        totalPercentage += entry.value['percentage'] as num;
        bestScore =
            bestScore < (entry.value['percentage'] as num)
                ? (entry.value['percentage'] as num).toDouble()
                : bestScore;
      }

      double averageScore =
          uniqueQuizzes > 0 ? totalPercentage / uniqueQuizzes : 0.0;

      return {
        'quizzesCompleted': quizzesCompleted,
        'uniqueQuizzes': uniqueQuizzes,
        'averageScore': averageScore,
        'totalPoints': userData['points'] ?? 0,
        'achievements': userData['achievements'] ?? [],
        'recentResults': recentResults,
        'bestScore': bestScore,
        'totalTimeSpent': totalTimeSpent,
      };
    } catch (e) {
      print('Error fetching user quiz statistics: $e');
      return {
        'quizzesCompleted': 0,
        'averageScore': 0.0,
        'totalPoints': 0,
        'achievements': [],
        'recentResults': [],
        'uniqueQuizzes': 0,
        'bestScore': 0.0,
        'totalTimeSpent': 0,
      };
    }
  }

  // Get user's completed quiz IDs
  Future<List<String>> getCompletedQuizIds() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data()!;
      List<dynamic> completedQuizIds = userData['completedQuizIds'] ?? [];

      return completedQuizIds.map((id) => id.toString()).toList();
    } catch (e) {
      print('Error fetching completed quiz IDs: $e');
      return [];
    }
  }

  // Get user's points
  Future<int> getUserPoints() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return 0;
      }

      final userData = userDoc.data()!;
      return userData['points'] ?? 0;
    } catch (e) {
      print('Error fetching user points: $e');
      return 0;
    }
  }

  // Get user's quiz results by quiz ID
  Future<Map<String, dynamic>?> getUserQuizResults(String quizId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final resultsSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('quizResults')
              .where('quizId', isEqualTo: quizId)
              .orderBy('completedAt', descending: true)
              .limit(1)
              .get();

      if (resultsSnapshot.docs.isEmpty) {
        return null;
      }

      final data = resultsSnapshot.docs.first.data();
      return {
        'id': resultsSnapshot.docs.first.id,
        ...data,
        'completedAt': data['completedAt'].toDate(),
      };
    } catch (e) {
      print('Error fetching user quiz results: $e');
      return null;
    }
  }
}
