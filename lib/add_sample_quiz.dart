import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSampleQuiz extends StatefulWidget {
  const AddSampleQuiz({super.key});

  @override
  State<AddSampleQuiz> createState() => _AddSampleQuizState();
}

class _AddSampleQuizState extends State<AddSampleQuiz> {
  bool _isLoading = false;
  String _result = '';

  Future<void> _addSampleQuiz() async {
    setState(() {
      _isLoading = true;
      _result = 'Adding sample quiz...';
    });

    try {
      // Create a sample quiz
      final sampleQuiz = {
        'title': 'Islamic Basics Quiz',
        'description': 'Test your knowledge of basic Islamic concepts',
        'difficulty': 'Easy',
        'category': 'Islamic Knowledge',
        'rewardPoints': 10,
        'imageUrl': 'assets/quizzes.jpg',
        'questions': [
          {
            'question': 'What is the first pillar of Islam?',
            'options': [
              'Salah (Prayer)',
              'Shahadah (Declaration of Faith)',
              'Sawm (Fasting)',
              'Zakat (Charity)'
            ],
            'correctOptionIndex': 1,
            'explanation': 'The first pillar of Islam is the Shahadah, which is the declaration of faith.'
          },
          {
            'question': 'How many times do Muslims pray each day?',
            'options': ['3 times', '4 times', '5 times', '6 times'],
            'correctOptionIndex': 2,
            'explanation': 'Muslims pray 5 times a day: Fajr, Dhuhr, Asr, Maghrib, and Isha.'
          },
          {
            'question': 'Which month do Muslims fast in?',
            'options': ['Shawwal', 'Ramadan', 'Rajab', 'Dhul-Hijjah'],
            'correctOptionIndex': 1,
            'explanation': 'Muslims fast during the month of Ramadan, which is the ninth month of the Islamic calendar.'
          },
          {
            'question': 'What is the holy book of Islam?',
            'options': ['Injeel', 'Torah', 'Quran', 'Zabur'],
            'correctOptionIndex': 2,
            'explanation': 'The Quran is the holy book of Islam, revealed to Prophet Muhammad (peace be upon him).'
          },
          {
            'question': 'Who was the first prophet in Islam?',
            'options': ['Ibrahim (Abraham)', 'Adam', 'Nuh (Noah)', 'Musa (Moses)'],
            'correctOptionIndex': 1,
            'explanation': 'Adam was the first prophet in Islam, as well as the first human being.'
          }
        ]
      };

      // Add the quiz to Firestore
      await FirebaseFirestore.instance.collection('quizzes').add(sampleQuiz);

      setState(() {
        _result = 'Sample quiz added successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error adding sample quiz: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sample Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Text(_result, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _addSampleQuiz,
              child: const Text('Add Sample Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
