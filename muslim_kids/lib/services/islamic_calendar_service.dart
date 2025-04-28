import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muslim_kids/models/islamic_event.dart';

class IslamicCalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'islamic_events';

  // Sample significant Islamic days
  final List<IslamicEvent> _sampleEvents = [
    IslamicEvent(
      id: '1',
      title: 'Islamic New Year',
      description: 'First day of the Hijri calendar.',
      hijriDay: 1,
      hijriMonth: 1,
      significance:
          'Marks the start of the Hijri calendar, commemorating Prophet Muhammad\'s (PBUH) migration from Makkah to Madinah.',
      sunnahToFollow:
          '- Reflect on the lessons of the Hijrah (patience, sacrifice, and trust in Allah)\n- Make sincere du\'a for a blessed year ahead\n- Start the year with good intentions and deeds',
      isHoliday: true,
    ),
    IslamicEvent(
      id: '2',
      title: 'Day of Ashura',
      description: 'Tenth day of Muharram.',
      hijriDay: 10,
      hijriMonth: 1,
      significance:
          '- Prophet Musa (AS) and the Israelites were saved from Pharaoh\'s army\n- Prophet Noah\'s (AS) ark landed on Mount Judi\n- The day when many other significant events in Islamic history occurred',
      sunnahToFollow:
          '- Fast on the 9th and 10th (or 10th and 11th) of Muharram\n- Give charity\n- Make du\'a for forgiveness\n- Pray nafl prayers',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '3',
      title: 'Mawlid al-Nabi',
      description: 'Birthday of Prophet Muhammad (PBUH).',
      hijriDay: 12,
      hijriMonth: 3,
      significance:
          'Commemorates the birth of Prophet Muhammad (PBUH), the final messenger of Allah.',
      sunnahToFollow:
          '- Read and reflect on the Seerah (life) of the Prophet\n- Increase Salawat (sending blessings upon the Prophet)\n- Follow his Sunnah in daily life\n- Be kind, help others, and spread peace',
      isHoliday: true,
    ),
    IslamicEvent(
      id: '4',
      title: 'Lailat al-Miraj',
      description: 'Night Journey and Ascension of Prophet Muhammad (PBUH).',
      hijriDay: 27,
      hijriMonth: 7,
      significance:
          'The night when Prophet Muhammad (PBUH) journeyed from Makkah to Jerusalem and then ascended to the heavens, where he received the command of five daily prayers.',
      sunnahToFollow:
          '- Increase in prayers, especially Nafl prayers\n- Recite Surah Al-Isra, which describes the journey\n- Seek forgiveness and make du\'a for guidance',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '5',
      title: 'Shab-e-Barat',
      description: 'Night of Forgiveness.',
      hijriDay: 15,
      hijriMonth: 8,
      significance:
          'Known as the "Night of Forgiveness," it is believed to be when Allah makes decisions about people\'s destinies for the coming year.',
      sunnahToFollow:
          '- Pray Nafl prayers\n- Seek forgiveness for past mistakes\n- Visit the graves of loved ones\n- Give charity',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '6',
      title: 'First day of Ramadan',
      description: 'Beginning of the month of fasting.',
      hijriDay: 1,
      hijriMonth: 9,
      significance:
          'The beginning of the holy month when fasting is obligatory, the Quran was revealed, and rewards for good deeds are multiplied.',
      sunnahToFollow:
          '- Fast with intention and sincerity\n- Increase Quran recitation\n- Give charity\n- Make du\'a, especially at iftar time',
      isHoliday: true,
    ),
    IslamicEvent(
      id: '7',
      title: 'Laylat al-Qadr',
      description: 'Night of Power.',
      hijriDay: 27,
      hijriMonth: 9,
      significance:
          'The "Night of Power" when the first verses of the Quran were revealed to Prophet Muhammad (PBUH). Worship on this night is better than a thousand months.',
      sunnahToFollow:
          '- Increase in prayer, especially Tahajjud\n- Recite Quran\n- Make du\'a, especially: "Allahumma innaka \'afuwwun tuhibbul \'afwa fa\'fu \'anni"\n- Perform I\'tikaf in the mosque',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '8',
      title: 'Eid al-Fitr',
      description: 'Festival of Breaking the Fast.',
      hijriDay: 1,
      hijriMonth: 10,
      significance:
          'Celebration marking the end of Ramadan and the month of fasting.',
      sunnahToFollow:
          '- Perform Ghusl (ritual bath)\n- Wear clean, nice clothes\n- Eat something sweet before the Eid prayer\n- Attend the Eid prayer\n- Give Zakat al-Fitr before the prayer\n- Exchange greetings and gifts',
      isHoliday: true,
    ),
    IslamicEvent(
      id: '9',
      title: 'Day of Arafah',
      description: 'Second day of the Hajj pilgrimage.',
      hijriDay: 9,
      hijriMonth: 12,
      significance:
          'The most important day of Hajj when pilgrims gather on Mount Arafah, seeking Allah\'s forgiveness and mercy.',
      sunnahToFollow:
          '- Fast if not performing Hajj\n- Make du\'a throughout the day\n- Seek forgiveness for sins\n- Perform extra acts of worship',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '10',
      title: 'Eid al-Adha',
      description: 'Festival of Sacrifice.',
      hijriDay: 10,
      hijriMonth: 12,
      significance:
          'Commemorates Prophet Ibrahim\'s (AS) willingness to sacrifice his son Ismail (AS) as an act of obedience to Allah.',
      sunnahToFollow:
          '- Perform Ghusl (ritual bath)\n- Wear best clothes\n- Attend Eid prayer\n- Perform Qurbani (animal sacrifice)\n- Distribute meat to family, friends, and the needy\n- Recite Takbeer-e-Tashreeq',
      isHoliday: true,
    ),
    IslamicEvent(
      id: '11',
      title: 'Hajj Begins',
      description: 'Annual pilgrimage to Makkah.',
      hijriDay: 8,
      hijriMonth: 12,
      significance:
          'The beginning of the annual pilgrimage to Makkah, which is the fifth pillar of Islam.',
      sunnahToFollow:
          '- For those not performing Hajj: Make du\'a for the pilgrims\n- Give charity\n- Learn about the rituals and significance of Hajj',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '12',
      title: 'Tasu\'a',
      description: 'Ninth day of Muharram.',
      hijriDay: 9,
      hijriMonth: 1,
      significance:
          'The day before Ashura, recommended for fasting along with Ashura.',
      sunnahToFollow:
          '- Fast on this day along with Ashura\n- Give charity\n- Increase in worship',
      isHoliday: false,
    ),
  ];

  // Get all Islamic events
  Future<List<IslamicEvent>> getIslamicEvents() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection(_collectionName).get();

      if (querySnapshot.docs.isEmpty) {
        // If no events in Firestore, upload sample events
        await _uploadSampleEventsToFirestore();
        return _sampleEvents;
      }

      // Map Firestore documents to IslamicEvent objects
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return IslamicEvent.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting Islamic events: $e');
      // Return sample events if there's an error
      return _sampleEvents;
    }
  }

  // Get a map of events indexed by 'day-month' format
  Future<Map<String, IslamicEvent>> getEventsMap() async {
    final events = await getIslamicEvents();
    final Map<String, IslamicEvent> eventsMap = {};

    for (var event in events) {
      eventsMap[event.dateKey] = event;
    }

    return eventsMap;
  }

  // Get event for a specific Hijri date
  Future<IslamicEvent?> getEventForDate(int day, int month) async {
    try {
      String dateKey = '$day-$month';
      Map<String, IslamicEvent> eventsMap = await getEventsMap();

      return eventsMap[dateKey];
    } catch (e) {
      print('Error getting event for date: $e');
      return null;
    }
  }

  // Upload sample events to Firestore
  Future<void> _uploadSampleEventsToFirestore() async {
    try {
      WriteBatch batch = _firestore.batch();

      for (var event in _sampleEvents) {
        DocumentReference docRef =
            _firestore.collection(_collectionName).doc(event.id);
        batch.set(docRef, event.toMap());
      }

      await batch.commit();
      print('Sample Islamic events uploaded to Firestore');
    } catch (e) {
      print('Error uploading sample Islamic events: $e');
    }
  }
}
