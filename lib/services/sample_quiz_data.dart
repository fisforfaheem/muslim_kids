import 'package:cloud_firestore/cloud_firestore.dart';

class SampleQuizData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addSampleQuizzes() async {
    // Check if any quizzes already exist
    final existingQuizzes =
        await _firestore.collection('quizzes').limit(1).get();

    if (existingQuizzes.docs.isNotEmpty) {
      print('Sample quizzes already exist, skipping creation.');
      return;
    }

    // Define sample quizzes
    final List<Map<String, dynamic>> sampleQuizzes = [
      {
        'title': 'Basic Islamic Knowledge Quiz',
        'description':
            'Test your knowledge of basic Islamic concepts and practices with this beginner-friendly quiz.',
        'difficulty': 'Easy',
        'rewardPoints': 20,
        'category': 'General Knowledge',
        'imageUrl':
            'https://images.unsplash.com/photo-1564121211835-e88c852648ab?q=80&w=1000',
        'questions': [
          {
            'question': 'What is the first pillar of Islam?',
            'options': [
              'Prayer (Salah)',
              'Faith/Testimony (Shahada)',
              'Fasting (Sawm)',
              'Charity (Zakat)'
            ],
            'correctOptionIndex': 1,
            'explanation':
                'The first pillar of Islam is the Shahada, which is the testimony of faith: "There is no God but Allah, and Muhammad is the messenger of Allah."'
          },
          {
            'question': 'How many times do Muslims pray each day?',
            'options': ['3 times', '4 times', '5 times', '6 times'],
            'correctOptionIndex': 2,
            'explanation':
                'Muslims pray 5 times a day: Fajr (dawn), Dhuhr (noon), Asr (afternoon), Maghrib (sunset), and Isha (night).'
          },
          {
            'question': 'What is the name of the holy book in Islam?',
            'options': ['Injil', 'Torah', 'Quran', 'Bible'],
            'correctOptionIndex': 2,
            'explanation':
                'The Quran is the holy book of Islam, believed to be the word of Allah revealed to Prophet Muhammad through the angel Gabriel.'
          },
          {
            'question':
                'During which month do Muslims fast from dawn to sunset?',
            'options': ['Muharram', 'Rajab', 'Sha\'ban', 'Ramadan'],
            'correctOptionIndex': 3,
            'explanation':
                'Muslims fast during the month of Ramadan, the ninth month of the Islamic calendar.'
          },
          {
            'question': 'Who was the last prophet in Islam?',
            'options': [
              'Ibrahim (Abraham)',
              'Musa (Moses)',
              'Isa (Jesus)',
              'Muhammad'
            ],
            'correctOptionIndex': 3,
            'explanation':
                'Prophet Muhammad is believed to be the last prophet in Islam, often referred to as the "Seal of the Prophets."'
          },
          {
            'question':
                'What is the Arabic word for the obligatory charity in Islam?',
            'options': ['Sadaqah', 'Zakat', 'Infaq', 'Hibah'],
            'correctOptionIndex': 1,
            'explanation':
                'Zakat is the obligatory charity that every financially stable Muslim must give to the poor and needy.'
          },
          {
            'question': 'Which city is the birthplace of Prophet Muhammad?',
            'options': ['Medina', 'Jerusalem', 'Mecca', 'Damascus'],
            'correctOptionIndex': 2,
            'explanation':
                'Prophet Muhammad was born in Mecca, in present-day Saudi Arabia, around the year 570 CE.'
          },
          {
            'question': 'What is the name of the annual pilgrimage to Mecca?',
            'options': ['Umrah', 'Hajj', 'Ziyarah', 'Rihla'],
            'correctOptionIndex': 1,
            'explanation':
                'Hajj is the annual Islamic pilgrimage to Mecca, Saudi Arabia, which is mandatory for Muslims to perform at least once in their lifetime if they are physically and financially capable.'
          },
          {
            'question': 'What does "Islam" mean in Arabic?',
            'options': ['Peace', 'Submission', 'Truth', 'Faith'],
            'correctOptionIndex': 1,
            'explanation':
                'The word "Islam" in Arabic means "submission" or "surrender" to the will of Allah (God).'
          },
          {
            'question': 'Who was the first woman to accept Islam?',
            'options': ['Aisha', 'Khadijah', 'Fatimah', 'Maryam'],
            'correctOptionIndex': 1,
            'explanation':
                'Khadijah, who was also the wife of Prophet Muhammad, was the first woman to accept Islam.'
          }
        ]
      },
      {
        'title': 'Quran Stories Quiz',
        'description':
            'Test your knowledge about important stories and prophets mentioned in the Quran.',
        'difficulty': 'Medium',
        'rewardPoints': 30,
        'category': 'Quran',
        'imageUrl':
            'https://images.unsplash.com/photo-1609599006483-7a0441bb3970?q=80&w=1000',
        'questions': [
          {
            'question': 'Which prophet was swallowed by a whale?',
            'options': [
              'Yunus (Jonah)',
              'Musa (Moses)',
              'Nuh (Noah)',
              'Ibrahim (Abraham)'
            ],
            'correctOptionIndex': 0,
            'explanation':
                'Prophet Yunus (Jonah) was swallowed by a whale after he left his people without Allah\'s permission.'
          },
          {
            'question':
                'Which prophet was able to speak to animals and control the wind?',
            'options': [
              'Dawud (David)',
              'Suleiman (Solomon)',
              'Isa (Jesus)',
              'Yusuf (Joseph)'
            ],
            'correctOptionIndex': 1,
            'explanation':
                'Prophet Suleiman (Solomon) was given the ability to understand the language of animals and control the wind.'
          },
          {
            'question':
                'Which prophet built the Ark to save believers from the flood?',
            'options': ['Ibrahim (Abraham)', 'Lut (Lot)', 'Nuh (Noah)', 'Hud'],
            'correctOptionIndex': 2,
            'explanation':
                'Prophet Nuh (Noah) built the Ark by Allah\'s command to save the believers from the great flood.'
          },
          {
            'question':
                'Which prophet was thrown into a fire that was made cool by Allah\'s command?',
            'options': [
              'Ibrahim (Abraham)',
              'Musa (Moses)',
              'Ismail (Ishmael)',
              'Yaqub (Jacob)'
            ],
            'correctOptionIndex': 0,
            'explanation':
                'Prophet Ibrahim (Abraham) was thrown into a fire by King Nimrod, but Allah made the fire cool and safe for him.'
          },
          {
            'question':
                'The story of which prophet involves a dream about 7 fat cows and 7 lean ones?',
            'options': [
              'Ayub (Job)',
              'Yusuf (Joseph)',
              'Zakariya (Zechariah)',
              'Yahya (John)'
            ],
            'correctOptionIndex': 1,
            'explanation':
                'The story of Prophet Yusuf (Joseph) includes his interpretation of the king\'s dream about 7 fat cows being eaten by 7 lean ones, predicting 7 years of prosperity followed by 7 years of famine.'
          }
        ]
      },
      {
        'title': 'Islamic Etiquette Quiz',
        'description': 'Learn about the proper manners and etiquette in Islam.',
        'difficulty': 'Easy',
        'rewardPoints': 25,
        'category': 'Lifestyle',
        'imageUrl':
            'https://images.unsplash.com/photo-1572947625400-2d784d71aee5?q=80&w=1000',
        'questions': [
          {
            'question': 'What should a Muslim say before starting to eat?',
            'options': [
              'Alhamdulillah',
              'Bismillah',
              'MashaAllah',
              'SubhanAllah'
            ],
            'correctOptionIndex': 1,
            'explanation':
                'Muslims say "Bismillah" (In the name of Allah) before starting to eat or drink.'
          },
          {
            'question': 'What is the Islamic greeting?',
            'options': ['Hello', 'Good day', 'Assalamu Alaikum', 'Marhaba'],
            'correctOptionIndex': 2,
            'explanation':
                'The Islamic greeting is "Assalamu Alaikum" which means "Peace be upon you."'
          },
          {
            'question': 'What should a Muslim say when they hear good news?',
            'options': [
              'Alhamdulillah',
              'MashaAllah',
              'SubhanAllah',
              'Allahu Akbar'
            ],
            'correctOptionIndex': 1,
            'explanation':
                'Muslims say "MashaAllah" (What Allah has willed) when they see something they admire or hear good news.'
          },
          {
            'question': 'What should a Muslim say when they finish eating?',
            'options': [
              'Bismillah',
              'Jazakallah',
              'Alhamdulillah',
              'Insha\'Allah'
            ],
            'correctOptionIndex': 2,
            'explanation':
                'Muslims say "Alhamdulillah" (All praise is due to Allah) after finishing a meal as gratitude to Allah.'
          },
          {
            'question': 'Which hand should Muslims use for eating?',
            'options': ['Left hand', 'Right hand', 'Either hand', 'Both hands'],
            'correctOptionIndex': 1,
            'explanation':
                'Muslims are encouraged to eat with their right hand as it is a Sunnah (practice) of Prophet Muhammad.'
          }
        ]
      }
    ];

    // Add quizzes to Firestore
    for (var quiz in sampleQuizzes) {
      await _firestore.collection('quizzes').add(quiz);
    }

    print('Added ${sampleQuizzes.length} sample quizzes to Firestore.');
  }
}
