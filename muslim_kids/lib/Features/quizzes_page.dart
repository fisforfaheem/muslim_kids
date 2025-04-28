import 'package:flutter/material.dart';

class QuizzesPage extends StatelessWidget {
  const QuizzesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quizzes'),
      ),
      body: Center(
        child: Text('Quizzes Page'),
      ),
    );
  }
}
