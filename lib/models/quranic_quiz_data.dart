import 'package:muslim_kids/models/quiz_model.dart';

class QuranicQuizData {
  static List<QuizModel> getQuizzes() {
    return [
      QuizModel(
        id: 'quranic_basics_quiz',
        title: 'Quranic Basics Quiz',
        description: 'Test your knowledge of basic Quranic facts and stories',
        difficulty: 'Easy',
        rewardPoints: 20,
        category: 'Quran',
        imageUrl: 'assets/quizzes.jpg',
        questions: [
          QuizQuestion(
            question: 'How many chapters (Surahs) are there in the Quran?',
            options: ['114', '120', '100', '110'],
            correctOptionIndex: 0,
            explanation:
                'The Quran has 114 chapters or Surahs of varying lengths.',
          ),
          QuizQuestion(
            question: 'Which is the longest Surah in the Quran?',
            options: ['Al-Baqarah', 'Al-Imran', 'An-Nisa', 'Al-Maidah'],
            correctOptionIndex: 0,
            explanation:
                'Al-Baqarah (The Cow) is the longest chapter with 286 verses.',
          ),
          QuizQuestion(
            question: 'Which is the shortest Surah in the Quran?',
            options: ['Al-Kawthar', 'Al-Ikhlas', 'Al-Asr', 'Al-Fatiha'],
            correctOptionIndex: 0,
            explanation:
                'Al-Kawthar is the shortest chapter with only 3 verses.',
          ),
          QuizQuestion(
            question:
                'Who is known as "Kalimullah" (the one to whom Allah spoke directly)?',
            options: [
              'Prophet Musa (Moses)',
              'Prophet Ibrahim (Abraham)',
              'Prophet Isa (Jesus)',
              'Prophet Muhammad',
            ],
            correctOptionIndex: 0,
            explanation:
                'Prophet Musa (Moses) is known as Kalimullah because Allah spoke to him directly.',
          ),
          QuizQuestion(
            question: 'Which prophet is mentioned the most times in the Quran?',
            options: [
              'Prophet Musa (Moses)',
              'Prophet Ibrahim (Abraham)',
              'Prophet Nuh (Noah)',
              'Prophet Muhammad',
            ],
            correctOptionIndex: 0,
            explanation:
                'Prophet Musa (Moses) is mentioned by name 136 times in the Quran.',
          ),
          QuizQuestion(
            question: 'Which Surah begins without the Bismillah?',
            options: ['At-Tawbah', 'Al-Baqarah', 'Al-Fatiha', 'Al-Ikhlas'],
            correctOptionIndex: 0,
            explanation:
                'Surah At-Tawbah (The Repentance) is the only Surah that does not begin with Bismillah.',
          ),
          QuizQuestion(
            question: 'Which Surah is known as the "Heart of the Quran"?',
            options: [
              'Surah Yasin',
              'Surah Al-Fatiha',
              'Surah Al-Ikhlas',
              'Surah Ar-Rahman',
            ],
            correctOptionIndex: 0,
            explanation:
                'Surah Yasin is often referred to as the Heart of the Quran.',
          ),
          QuizQuestion(
            question: 'How many Juz (parts) is the Quran divided into?',
            options: ['30', '40', '50', '60'],
            correctOptionIndex: 0,
            explanation:
                'The Quran is divided into 30 equal parts called Juz for ease of recitation over a month.',
          ),
          QuizQuestion(
            question: 'What is the first revealed Surah of the Quran?',
            options: ['Al-Alaq', 'Al-Fatiha', 'Al-Baqarah', 'An-Nas'],
            correctOptionIndex: 0,
            explanation:
                'The first verses revealed were from Surah Al-Alaq beginning with "Read! In the name of your Lord who created..."',
          ),
          QuizQuestion(
            question: 'What is the last revealed Surah of the Quran?',
            options: ['An-Nasr', 'Al-Fatiha', 'Al-Ikhlas', 'Al-Baqarah'],
            correctOptionIndex: 0,
            explanation:
                'Surah An-Nasr (The Victory) is generally considered to be the last complete Surah revealed to Prophet Muhammad.',
          ),
        ],
      ),
      QuizModel(
        id: 'islamic_stories_quiz',
        title: 'Prophets in the Quran',
        description: 'Learn about the prophets mentioned in the Quran',
        difficulty: 'Medium',
        rewardPoints: 25,
        category: 'Quran',
        imageUrl: 'assets/videos.jpg',
        questions: [
          QuizQuestion(
            question: 'Who built the Ark as mentioned in the Quran?',
            options: [
              'Prophet Nuh (Noah)',
              'Prophet Ibrahim (Abraham)',
              'Prophet Musa (Moses)',
              'Prophet Dawud (David)',
            ],
            correctOptionIndex: 0,
            explanation:
                'Prophet Nuh (Noah) built the Ark to save believers and animals from the great flood.',
          ),
          QuizQuestion(
            question:
                'Which prophet was thrown into a fire that Allah made cool and safe?',
            options: [
              'Prophet Ibrahim (Abraham)',
              'Prophet Musa (Moses)',
              'Prophet Yunus (Jonah)',
              'Prophet Yusuf (Joseph)',
            ],
            correctOptionIndex: 0,
            explanation:
                'Prophet Ibrahim was thrown into a fire by King Nimrod, but Allah made it cool and safe for him.',
          ),
          QuizQuestion(
            question: 'Which prophet was swallowed by a whale?',
            options: [
              'Prophet Yunus (Jonah)',
              'Prophet Yusuf (Joseph)',
              'Prophet Ayyub (Job)',
              'Prophet Sulaiman (Solomon)',
            ],
            correctOptionIndex: 0,
            explanation:
                'Prophet Yunus (Jonah) was swallowed by a whale and glorified Allah from its belly.',
          ),
          QuizQuestion(
            question: 'Which prophet could understand the language of animals?',
            options: [
              'Prophet Sulaiman (Solomon)',
              'Prophet Dawud (David)',
              'Prophet Musa (Moses)',
              'Prophet Ibrahim (Abraham)',
            ],
            correctOptionIndex: 0,
            explanation:
                'Prophet Sulaiman (Solomon) was blessed with the ability to understand the language of animals including ants and birds.',
          ),
          QuizQuestion(
            question:
                'Which prophet was known for his incredible patience during hardship?',
            options: [
              'Prophet Ayyub (Job)',
              'Prophet Yunus (Jonah)',
              'Prophet Yusuf (Joseph)',
              'Prophet Zakariya (Zechariah)',
            ],
            correctOptionIndex: 0,
            explanation:
                'Prophet Ayyub (Job) is known for his exemplary patience during severe trials of illness and loss.',
          ),
          QuizQuestion(
            question: 'Which prophet was sold as a slave by his brothers?',
            options: [
              'Prophet Yusuf (Joseph)',
              'Prophet Yahya (John)',
              'Prophet Ismail (Ishmael)',
              'Prophet Lut (Lot)',
            ],
            correctOptionIndex: 0,
            explanation:
                'Prophet Yusuf (Joseph) was thrown into a well and then sold as a slave by his jealous brothers.',
          ),
          QuizQuestion(
            question: 'Which prophet\'s miracle was splitting the sea?',
            options: [
              'Prophet Musa (Moses)',
              'Prophet Nuh (Noah)',
              'Prophet Isa (Jesus)',
              'Prophet Muhammad',
            ],
            correctOptionIndex: 0,
            explanation:
                'Prophet Musa (Moses) split the sea with his staff when escaping from Pharaoh and his army.',
          ),
          QuizQuestion(
            question:
                'Which prophet was able to heal the blind and the lepers by Allah\'s permission?',
            options: [
              'Prophet Isa (Jesus)',
              'Prophet Muhammad',
              'Prophet Dawud (David)',
              'Prophet Sulaiman (Solomon)',
            ],
            correctOptionIndex: 0,
            explanation:
                'Prophet Isa (Jesus) could heal the blind and lepers by Allah\'s permission as mentioned in the Quran.',
          ),
          QuizQuestion(
            question: 'Which prophet was instructed to sacrifice his son?',
            options: [
              'Prophet Ibrahim (Abraham)',
              'Prophet Muhammad',
              'Prophet Dawud (David)',
              'Prophet Nuh (Noah)',
            ],
            correctOptionIndex: 0,
            explanation:
                'Prophet Ibrahim (Abraham) was commanded to sacrifice his son Ismail, but Allah replaced him with a ram.',
          ),
          QuizQuestion(
            question: 'Which prophet was given the Zabur (Psalms)?',
            options: [
              'Prophet Dawud (David)',
              'Prophet Musa (Moses)',
              'Prophet Ibrahim (Abraham)',
              'Prophet Isa (Jesus)',
            ],
            correctOptionIndex: 0,
            explanation:
                'Prophet Dawud (David) was given the Zabur (Psalms) by Allah.',
          ),
        ],
      ),
    ];
  }
}
