import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all available quizzes
  Future<List<Map<String, dynamic>>> getQuizzes() async {
    try {
      final snapshot = await _firestore.collection('quizzes').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error fetching quizzes: $e');
      return [];
    }
  }

  // Get a specific quiz by ID
  Future<Map<String, dynamic>?> getQuizById(String quizId) async {
    try {
      final doc = await _firestore.collection('quizzes').doc(quizId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      print('Error fetching quiz $quizId: $e');
      return null;
    }
  }

  // Submit quiz result
  Future<bool> submitQuizResult({
    required String quizId,
    required String quizTitle,
    required int score,
    required int totalQuestions,
    required int timeSpentInSeconds,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final percentage = (score / totalQuestions) * 100;
      final timestamp = Timestamp.now();

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

        // Add points to user based on percentage scored
        int pointsEarned =
            (percentage / 10).round(); // 10 points for 100%, 1 point for 10%
        int currentPoints = userData['points'] ?? 0;

        // Check for achievements based on quiz completion
        List<dynamic> achievements = userData['achievements'] ?? [];

        // First quiz achievement
        if (quizzesCompleted == 0) {
          achievements.add({
            'title': 'First Quiz Completed',
            'description': 'Completed your first quiz!',
            'earnedAt': timestamp,
            'icon': '🎓',
          });
        }

        // 5 quizzes achievement
        if (quizzesCompleted == 4) {
          achievements.add({
            'title': 'Quiz Champion',
            'description': 'Completed 5 quizzes!',
            'earnedAt': timestamp,
            'icon': '🏆',
          });
        }

        // Perfect score achievement
        if (percentage == 100) {
          achievements.add({
            'title': 'Perfect Score',
            'description': 'Earned a perfect score on a quiz!',
            'earnedAt': timestamp,
            'icon': '⭐',
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
      print('Error submitting quiz result: $e');
      return false;
    }
  }

  // Get user's quiz history
  Future<List<Map<String, dynamic>>> getUserQuizHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
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

  // Get user's quiz statistics
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
        };
      }

      final userData = userDoc.data()!;

      // Get recent quiz results
      final resultsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quizResults')
          .orderBy('completedAt', descending: true)
          .limit(5)
          .get();

      final recentResults = resultsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'completedAt': data['completedAt'].toDate(),
        };
      }).toList();

      // Calculate average score
      double averageScore = 0.0;
      final quizzesCompleted = userData['quizzesCompleted'] ?? 0;
      final totalScore = userData['totalQuizScore'] ?? 0;

      if (quizzesCompleted > 0) {
        averageScore = totalScore / quizzesCompleted;
      }

      return {
        'quizzesCompleted': quizzesCompleted,
        'averageScore': averageScore,
        'totalPoints': userData['points'] ?? 0,
        'achievements': userData['achievements'] ?? [],
        'recentResults': recentResults,
      };
    } catch (e) {
      print('Error fetching user quiz statistics: $e');
      return {
        'quizzesCompleted': 0,
        'averageScore': 0.0,
        'totalPoints': 0,
        'achievements': [],
        'recentResults': [],
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

      final resultsSnapshot = await _firestore
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
