import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestQuizzes extends StatefulWidget {
  const TestQuizzes({super.key});

  @override
  State<TestQuizzes> createState() => _TestQuizzesState();
}

class _TestQuizzesState extends State<TestQuizzes> {
  bool _isLoading = true;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _checkQuizzes();
  }

  Future<void> _checkQuizzes() async {
    setState(() {
      _isLoading = true;
      _result = 'Checking quizzes...';
    });

    try {
      // Check if the quizzes collection exists and has documents
      final quizzesSnapshot = await FirebaseFirestore.instance.collection('quizzes').get();
      
      if (quizzesSnapshot.docs.isEmpty) {
        setState(() {
          _result = 'No quizzes found in the database. The quizzes collection is empty.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _result = 'Found ${quizzesSnapshot.docs.length} quizzes in the database:\n\n';
          
          for (var doc in quizzesSnapshot.docs) {
            _result += 'Quiz ID: ${doc.id}\n';
            _result += 'Title: ${doc.data()['title'] ?? 'No title'}\n';
            _result += 'Questions: ${(doc.data()['questions'] as List?)?.length ?? 0}\n\n';
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error checking quizzes: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Quizzes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_result),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkQuizzes,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
