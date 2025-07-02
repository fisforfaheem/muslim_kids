import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:muslim_kids/models/badge_model.dart';
import 'package:muslim_kids/services/quiz_service.dart';

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final QuizService _quizService = QuizService();

  final List<BadgeModel> _availableBadges = [
    const BadgeModel(
      id: 'quiz_novice',
      name: 'Quiz Novice',
      description: 'You\'ve completed your first quiz! Keep going!',
      icon: Icons.school_outlined,
      color: Colors.blue,
      criteria: 'Complete 1 quiz',
    ),
    const BadgeModel(
      id: 'quiz_apprentice',
      name: 'Quiz Apprentice',
      description: 'Five quizzes down! You\'re getting good at this.',
      icon: Icons.lightbulb_outline,
      color: Colors.green,
      criteria: 'Complete 5 quizzes',
    ),
    const BadgeModel(
      id: 'quiz_master',
      name: 'Quiz Master',
      description: 'A true master of knowledge! You\'ve completed 10 quizzes.',
      icon: Icons.star_border,
      color: Colors.amber,
      criteria: 'Complete 10 quizzes',
    ),
    const BadgeModel(
      id: 'perfect_score',
      name: 'Perfect Score',
      description: 'Flawless victory! You got 100% on a quiz.',
      icon: Icons.check_circle_outline,
      color: Colors.purple,
      criteria: 'Get a 100% score',
    ),
    const BadgeModel(
      id: 'prayer_starter',
      name: 'Prayer Starter',
      description: 'You\'re building a great habit. 3 days of prayer!',
      icon: Icons.favorite_border,
      color: Colors.pink,
      criteria: '3-day prayer streak',
    ),
    const BadgeModel(
      id: 'devout_worshipper',
      name: 'Devout Worshipper',
      description: 'Masha\'Allah! A full week of prayers.',
      icon: Icons.favorite,
      color: Colors.red,
      criteria: '7-day prayer streak',
    ),
  ];

  List<BadgeModel> getAvailableBadges() => _availableBadges;

  Future<List<String>> getEarnedBadgeIds() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('badges')
              .get();

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting earned badges: $e');
      return [];
    }
  }

  Future<List<BadgeModel>> checkAndAwardBadges() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    final earnedBadgeIds = await getEarnedBadgeIds();
    final userStats = await _quizService.getUserQuizStatistics();
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final int quizzesCompleted = userStats['quizzesCompleted'] ?? 0;
    final double bestScore = userStats['bestScore'] ?? 0.0;
    final int prayerStreak = userData['prayerStreak'] ?? 0;

    List<BadgeModel> newlyAwardedBadges = [];

    for (final badge in _availableBadges) {
      if (earnedBadgeIds.contains(badge.id)) continue;

      bool criteriaMet = false;
      switch (badge.id) {
        case 'quiz_novice':
          if (quizzesCompleted >= 1) criteriaMet = true;
          break;
        case 'quiz_apprentice':
          if (quizzesCompleted >= 5) criteriaMet = true;
          break;
        case 'quiz_master':
          if (quizzesCompleted >= 10) criteriaMet = true;
          break;
        case 'perfect_score':
          if (bestScore == 100.0) criteriaMet = true;
          break;
        case 'prayer_starter':
          if (prayerStreak >= 3) criteriaMet = true;
          break;
        case 'devout_worshipper':
          if (prayerStreak >= 7) criteriaMet = true;
          break;
      }

      if (criteriaMet) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('badges')
            .doc(badge.id)
            .set({
              'name': badge.name,
              'earnedAt': FieldValue.serverTimestamp(),
            });
        newlyAwardedBadges.add(badge);
      }
    }
    return newlyAwardedBadges;
  }
}
