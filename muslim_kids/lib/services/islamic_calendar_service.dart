import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muslim_kids/models/islamic_event.dart';

class IslamicCalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'islamic_events';

  // Significant Islamic days with enhanced details
  final List<IslamicEvent> _sampleEvents = [
    IslamicEvent(
      id: '1',
      title: 'Islamic New Year',
      description: 'First day of the Hijri calendar, 1st of Muharram.',
      hijriDay: 1,
      hijriMonth: 1,
      significance:
          'Marks the start of the Hijri calendar, commemorating Prophet Muhammad\'s (PBUH) migration from Makkah to Madinah in 622 CE. This migration, known as the Hijrah, was a pivotal moment in Islamic history that marked the beginning of the spread of Islam and the establishment of the first Muslim community and state.',
      sunnahToFollow:
          '- Reflect on the lessons of the Hijrah (patience, sacrifice, and trust in Allah)\n- Make sincere du\'a for a blessed year ahead\n- Start the year with good intentions and deeds\n- Fast on this day following the example of some companions\n- Recite Surah Yasin and make du\'a for protection and blessings',
      isHoliday: true,
    ),
    IslamicEvent(
      id: '2',
      title: 'Day of Ashura',
      description: 'Tenth day of Muharram, a day of historical significance.',
      hijriDay: 10,
      hijriMonth: 1,
      significance:
          '- The day when Allah saved Prophet Musa (AS) and the Israelites from Pharaoh\'s army by parting the Red Sea\n- The day when Prophet Noah\'s (AS) ark landed on Mount Judi after the flood\n- The day when Allah accepted the repentance of Prophet Adam (AS)\n- The day when Prophet Ibrahim (AS) was saved from the fire\n- The day when Prophet Yunus (AS) was released from the belly of the whale\n- The day when Prophet Yusuf (AS) was released from prison',
      sunnahToFollow:
          '- Fast on the 9th and 10th (or 10th and 11th) of Muharram as the Prophet (PBUH) did\n- Give extra charity on this day\n- Be generous to your family and those in need\n- Make du\'a for forgiveness and blessings\n- Pray nafl prayers to increase rewards\n- Spend time in dhikr (remembrance of Allah)',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '3',
      title: 'Milad-un Nabi',
      description:
          'Birthday of Prophet Muhammad (PBUH), 12th of Rabi al-Awwal.',
      hijriDay: 12,
      hijriMonth: 3,
      significance:
          'Commemorates the birth of Prophet Muhammad (PBUH), the final messenger of Allah. Born in Makkah in the Year of the Elephant (approximately 570 CE), his birth marked the beginning of a new era of guidance for humanity. Prophet Muhammad (PBUH) was sent as a mercy to all worlds, bringing the final revelation of the Quran and establishing the perfect example for mankind to follow.',
      sunnahToFollow:
          '- Study and reflect on the Seerah (life) of the Prophet (PBUH)\n- Increase Salawat (sending blessings upon the Prophet)\n- Learn and teach hadiths of the Prophet (PBUH)\n- Follow his Sunnah in daily life with increased dedication\n- Be kind, help others, and spread peace as he did\n- Express gratitude to Allah for sending Prophet Muhammad (PBUH) as a guide\n- Share stories of the Prophet\'s life with children',
      isHoliday: true,
    ),
    IslamicEvent(
      id: '4',
      title: 'Lailat al-Miraj',
      description:
          'Night Journey and Ascension of Prophet Muhammad (PBUH), 27th of Rajab.',
      hijriDay: 27,
      hijriMonth: 7,
      significance:
          'The miraculous night journey (Isra) when Prophet Muhammad (PBUH) traveled from Makkah to Jerusalem on the Buraq, and then ascended (Miraj) through the seven heavens where he received the command of five daily prayers. During this journey, the Prophet (PBUH) met earlier prophets including Ibrahim, Musa, and Isa (peace be upon them all), and was shown both Paradise and Hell. This event demonstrated Allah\'s power and the special status of Prophet Muhammad (PBUH).',
      sunnahToFollow:
          '- Increase in prayers, especially Tahajjud and Nafl prayers\n- Recite and reflect on Surah Al-Isra, which describes the journey\n- Express gratitude for the gift of Salah (prayer)\n- Seek forgiveness and make du\'a for guidance\n- Learn about the details of Isra and Miraj to strengthen your faith\n- Appreciate the spiritual connection between Jerusalem and Makkah\n- Teach children about this miraculous journey',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '5',
      title: 'Shab-e-Barat',
      description: 'Night of Forgiveness, 15th of Shaban.',
      hijriDay: 15,
      hijriMonth: 8,
      significance:
          'Known as the "Night of Forgiveness" or "Night of Freedom from Fire," it is believed to be when Allah makes decisions about people\'s destinies for the coming year. On this night, Allah is said to descend to the lowest heaven and offer forgiveness to His servants. Many scholars consider this a special night for seeking forgiveness and making du\'a, as Allah\'s mercy is particularly abundant during this time.',
      sunnahToFollow:
          '- Pray Tahajjud and other Nafl (voluntary) prayers\n- Recite Surah Yasin and make sincere du\'a\n- Seek forgiveness for past mistakes with true repentance\n- Visit the graves of loved ones and pray for the deceased\n- Give charity to the poor and needy\n- Fast on the 15th of Shaban (the following day)\n- Spend the night in worship rather than festivities\n- Reconcile broken relationships and forgive those who have wronged you',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '6',
      title: 'First day of Ramadan',
      description: 'Beginning of the holy month of fasting, 1st of Ramadan.',
      hijriDay: 1,
      hijriMonth: 9,
      significance:
          'The beginning of the blessed month when fasting is obligatory for adult Muslims. Ramadan is when the first verses of the Holy Quran were revealed to Prophet Muhammad (PBUH) through Angel Jibreel. It is a month of spiritual purification, self-discipline, and increased devotion. During Ramadan, the gates of Paradise are opened, the gates of Hell are closed, and the devils are chained. Rewards for good deeds are multiplied, and it is a special opportunity for gaining Allah\'s mercy and forgiveness.',
      sunnahToFollow:
          '- Fast with proper intention (niyyah) and sincerity\n- Increase Quran recitation and reflection\n- Pray Taraweeh prayers in congregation if possible\n- Give more in charity, especially to feed the hungry\n- Wake up for Suhoor as it is a blessed meal\n- Make du\'a at iftar time as it is a time when du\'as are accepted\n- Practice self-restraint in speech and behavior\n- Seek the Night of Power (Laylat al-Qadr) in the last ten nights\n- Avoid wasting time on worldly entertainment',
      isHoliday: true,
    ),
    IslamicEvent(
      id: '7',
      title: 'Laylat al-Qadr',
      description: 'Night of Power, typically observed on the 27th of Ramadan.',
      hijriDay: 27,
      hijriMonth: 9,
      significance:
          'The "Night of Power" or "Night of Decree" when the first verses of the Quran were revealed to Prophet Muhammad (PBUH). It is considered the most blessed night of the year, as Allah states in the Quran that worship on this night is better than a thousand months (over 83 years). It is one of the odd-numbered nights in the last ten days of Ramadan (most commonly believed to be the 27th). On this night, angels descend to earth, and Allah decrees what will occur during the upcoming year.',
      sunnahToFollow:
          '- Increase in prayer, especially Tahajjud (night prayer)\n- Recite and reflect on the Quran deeply\n- Perform I\'tikaf (spiritual retreat) in the mosque if possible\n- Make abundant du\'a, especially the du\'a taught by the Prophet (PBUH): "Allahumma innaka \'afuwwun tuhibbul \'afwa fa\'fu \'anni" (O Allah, You are the Pardoner, You love to pardon, so pardon me)\n- Seek forgiveness with sincerity and tears\n- Give charity generously\n- Spend the entire night in worship if able\n- Reflect on the Surah Al-Qadr (Chapter 97) of the Quran',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '8',
      title: 'Eid al-Fitr',
      description: 'Festival of Breaking the Fast, 1st of Shawwal.',
      hijriDay: 1,
      hijriMonth: 10,
      significance:
          'Celebration marking the end of Ramadan and the month of fasting. It is a day of joy, gratitude, and brotherhood, where Muslims thank Allah for the strength and opportunity to fast during Ramadan. Eid al-Fitr emphasizes community, charity, and togetherness, as Muslims gather for special prayers and visit family and friends. It reminds us that after a month of spiritual discipline, we celebrate not just with feasting but by showing compassion to those less fortunate.',
      sunnahToFollow:
          '- Perform Ghusl (ritual bath) before the Eid prayer\n- Wear your best, clean clothes\n- Apply perfume (for men) and look your best\n- Eat something sweet before the Eid prayer (preferably an odd number of dates)\n- Walk to the prayer ground if possible\n- Take different routes to and from the prayer\n- Attend the Eid prayer congregation\n- Give Zakat al-Fitr before the Eid prayer\n- Exchange greetings saying "Eid Mubarak" or "Taqabbal Allahu minna wa minkum" (May Allah accept from us and from you)\n- Visit family and friends and share meals\n- Give gifts, especially to children\n- Remember the less fortunate and include them in your celebration',
      isHoliday: true,
    ),
    IslamicEvent(
      id: '9',
      title: 'Day of Arafah',
      description: 'Most important day of Hajj, 9th of Dhul Hijjah.',
      hijriDay: 9,
      hijriMonth: 12,
      significance:
          'The most important day of Hajj when pilgrims gather on Mount Arafah, seeking Allah\'s forgiveness and mercy. The Prophet Muhammad (PBUH) said, "Hajj is Arafah," highlighting its central importance to the pilgrimage. It is believed that on this day, Allah comes close to His servants and takes pride in them before the angels. It is also the day when Allah perfected the religion of Islam, as mentioned in the Quran (5:3). For non-pilgrims, fasting on this day expiates sins of the previous year and the coming year.',
      sunnahToFollow:
          '- Fast if not performing Hajj (one of the most rewarded voluntary fasts)\n- Make abundant du\'a throughout the day, especially between Asr and Maghrib\n- Recite the Quran and do dhikr (remembrance of Allah)\n- Seek forgiveness for past sins with sincere repentance\n- Give charity on this blessed day\n- Perform extra voluntary prayers\n- Recite the special du\'a of the Day of Arafah that the Prophet (PBUH) taught\n- Avoid arguments, bad language, and sinful activities to maximize the day\'s blessings',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '10',
      title: 'Eid al-Adha',
      description: 'Festival of Sacrifice, 10th of Dhul Hijjah.',
      hijriDay: 10,
      hijriMonth: 12,
      significance:
          'Commemorates Prophet Ibrahim\'s (AS) willingness to sacrifice his son Ismail (AS) as an act of obedience to Allah\'s command, and Allah\'s mercy in replacing the son with a ram. It is a celebration of faith, obedience, and submission to Allah\'s will. Eid al-Adha coincides with the completion of Hajj and honors the tradition of sacrifice. The meat from sacrificed animals is divided into three parts: one for the family, one for friends and neighbors, and one for the poor and needy, emphasizing the importance of charity and community.',
      sunnahToFollow:
          '- Perform Ghusl (ritual bath) in the morning\n- Wear your best and cleanest clothes\n- Attend the Eid prayer congregation\n- Take different routes to and from the prayer\n- Perform Qurbani (animal sacrifice) after the prayer if financially able\n- Distribute the meat in three portions: family, friends, and the needy\n- Recite Takbeer-e-Tashreeq from Fajr of 9th Dhul Hijjah until Asr of the 13th\n- Abstain from cutting hair or nails until after the sacrifice\n- Visit family and friends to strengthen bonds\n- Show gratitude to Allah for His blessings\n- Remember the spirit of sacrifice in all aspects of life',
      isHoliday: true,
    ),
    IslamicEvent(
      id: '11',
      title: 'Hajj Begins',
      description: 'Annual pilgrimage to Makkah begins, 8th of Dhul Hijjah.',
      hijriDay: 8,
      hijriMonth: 12,
      significance:
          'The beginning of the annual pilgrimage to Makkah, which is the fifth pillar of Islam. Hajj is obligatory once in a lifetime for every adult Muslim who is physically and financially able. The rituals of Hajj commemorate the experiences of Prophet Ibrahim (AS) and his family, and symbolize the unity, equality, and brotherhood of Muslims worldwide. Hajj is a profound spiritual journey that represents the human\'s return to Allah and seeking His forgiveness.',
      sunnahToFollow:
          '- For those not performing Hajj: Make du\'a for the pilgrims\' safety and acceptance of their Hajj\n- Give charity in solidarity with the pilgrims\n- Learn about the rituals and significance of Hajj to deepen understanding\n- Follow the Hajj journey through media to feel connected\n- Fast during the first 9 days of Dhul Hijjah, especially the Day of Arafah\n- Increase in good deeds during these blessed days\n- Perform the Takbeer, Tahmeed, and Tahleel regularly\n- Make a sincere intention to perform Hajj when able',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '12',
      title: 'Tasu\'a',
      description: 'Ninth day of Muharram, the day before Ashura.',
      hijriDay: 9,
      hijriMonth: 1,
      significance:
          'The day before Ashura, recommended for fasting along with Ashura. The Prophet Muhammad (PBUH) intended to fast on this day to distinguish the Islamic fast from that of the Jews who only fasted on the 10th. It is a day of preparation for the significant day of Ashura and holds special blessings of its own.',
      sunnahToFollow:
          '- Fast on this day along with Ashura (the 10th)\n- Give charity to those in need\n- Increase in worship and dhikr\n- Recite more Quran than usual\n- Spend time teaching children about the significance of these days\n- Make special du\'a for yourself and the ummah\n- Visit the sick and help the needy',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '13',
      title: '15th of Sha\'ban',
      description: 'A blessed day preceding Shab-e-Barat.',
      hijriDay: 15,
      hijriMonth: 8,
      significance:
          'The day following Shab-e-Barat (the Night of Forgiveness). It marks the transition to preparation for Ramadan, which begins two weeks later. Some hadiths mention that Allah determines the destiny of all people for the coming year on this night, recording who will be born, who will die, and other significant events.',
      sunnahToFollow:
          '- Fast during the day if able (following the night of Shab-e-Barat)\n- Continue making du\'a and seeking forgiveness\n- Give charity to the poor and needy\n- Begin preparing spiritually for the upcoming month of Ramadan\n- Recite Quran and reflect on its meanings\n- Reconcile with those with whom you have disputes',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '14',
      title: 'Conquest of Makkah',
      description: 'Prophet Muhammad\'s (PBUH) peaceful conquest of Makkah.',
      hijriDay: 20,
      hijriMonth: 8,
      significance:
          'The day when Prophet Muhammad (PBUH) and the Muslims peacefully conquered Makkah in the 8th year after Hijrah (630 CE). This marked a significant turning point in Islamic history as the Prophet (PBUH) showed incredible mercy by forgiving those who had persecuted him and his followers for years. He declared general amnesty and cleansed the Ka\'bah of idols, restoring it to the worship of One God as built by Prophet Ibrahim (AS).',
      sunnahToFollow:
          '- Reflect on the Prophet\'s magnanimity and forgiveness\n- Practice forgiveness towards those who have wronged you\n- Learn the details of this historical event and its lessons\n- Teach children about the importance of mercy and forgiveness\n- Make du\'a for the unity of the Muslim ummah\n- Strive to overcome personal "idols" (ego, desires, etc.)',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '15',
      title: 'Battle of Badr',
      description: 'First major battle between Muslims and Quraysh.',
      hijriDay: 17,
      hijriMonth: 2,
      significance:
          'The first major battle fought by Prophet Muhammad (PBUH) and his companions against the Quraysh of Makkah on the 17th of Ramadan in the 2nd year after Hijrah (624 CE). Despite being vastly outnumbered (313 Muslims against 1,000 Makkans), the Muslims achieved a decisive victory with divine help. The Quran refers to this battle as the "Day of Criterion" (Furqan) as it distinguished truth from falsehood and established Islam\'s presence in Arabia.',
      sunnahToFollow:
          '- Study the details and strategies of the battle\n- Reflect on the faith and courage of the companions\n- Remember that victory comes from Allah, not from numbers or equipment\n- Make du\'a for strength in facing life\'s challenges\n- Give charity in remembrance of the sacrifices made\n- Strengthen your trust in Allah\'s help during difficult times',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '16',
      title: 'Laylat al-Bara\'ah',
      description: 'Another name for Shab-e-Barat, Night of Freedom from Fire.',
      hijriDay: 15,
      hijriMonth: 8,
      significance:
          'Also known as Shab-e-Barat in South Asian countries, this night is called the "Night of Freedom from Fire" or "Night of Records." Many Muslims believe that on this night, Allah records the destinies of all people for the coming year, including who will be born, who will die, and who will make the pilgrimage to Makkah.',
      sunnahToFollow:
          '- Spend the night in worship and prayer\n- Recite the Quran, especially Surah Yasin\n- Seek forgiveness with sincerity\n- Make du\'a for good health, sustenance, and well-being\n- Give charity to the needy\n- Visit the cemetery to pray for the deceased\n- Reflect on one\'s mortality and prepare for the afterlife',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '17',
      title: 'Last Ten Days of Ramadan',
      description: 'Most blessed nights of Ramadan containing Laylat al-Qadr.',
      hijriDay: 21,
      hijriMonth: 9,
      significance:
          'The final ten days of Ramadan are considered the most blessed part of the month, containing Laylat al-Qadr (the Night of Power). The Prophet Muhammad (PBUH) used to increase his worship during these days, spending the nights in prayer and waking his family to do the same. Many Muslims practice I\'tikaf (spiritual retreat) during this time, secluding themselves in the mosque to focus entirely on worship.',
      sunnahToFollow:
          '- Increase worship and night prayers (Tahajjud)\n- Perform I\'tikaf in the mosque if possible\n- Recite more Quran than in the earlier part of Ramadan\n- Increase charity and good deeds\n- Search for Laylat al-Qadr on the odd nights (21st, 23rd, 25th, 27th, 29th)\n- Make abundant du\'a, especially for forgiveness\n- Reduce worldly activities to focus on spiritual growth',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '18',
      title: 'Birthday of Imam Ali',
      description: 'Birth of Prophet Muhammad\'s (PBUH) cousin and son-in-law.',
      hijriDay: 13,
      hijriMonth: 7,
      significance:
          'Commemorates the birth of Imam Ali ibn Abi Talib (RA), cousin and son-in-law of Prophet Muhammad (PBUH), born inside the Ka\'bah in Makkah. Ali (RA) was the first young male to accept Islam, was known for his wisdom, courage, and deep knowledge of the Quran, and later became the fourth Rightly Guided Caliph. He is highly respected across all Islamic traditions for his closeness to the Prophet (PBUH) and his unwavering commitment to justice.',
      sunnahToFollow:
          '- Learn about the life and teachings of Imam Ali (RA)\n- Study his wisdom from Nahj al-Balagha (collection of his sermons and letters)\n- Emulate his commitment to justice and truth\n- Increase in charitable acts as Ali (RA) was known for his generosity\n- Strengthen family bonds as he exemplified\n- Seek knowledge, as Ali (RA) said: "Knowledge is better than wealth"',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '19',
      title: 'First Revelation',
      description:
          'Angel Jibreel brought the first Quranic verses to Prophet Muhammad (PBUH).',
      hijriDay: 17,
      hijriMonth: 9,
      significance:
          'Commemorates the first revelation of the Quran to Prophet Muhammad (PBUH) through Angel Jibreel in the Cave of Hira. The first words revealed were "Iqra" (Read), beginning Surah Al-Alaq. This marked the beginning of Prophet Muhammad\'s (PBUH) prophethood and the start of the final divine message to humanity.',
      sunnahToFollow:
          '- Recite and reflect on Surah Al-Alaq (96:1-5)\n- Express gratitude for the blessing of the Quran\n- Renew commitment to reading, understanding, and implementing the Quran\n- Share the story of the first revelation with children\n- Increase in worship, especially during Ramadan when this event is commemorated\n- Seek knowledge, as the first command was to "read"',
      isHoliday: false,
    ),
    IslamicEvent(
      id: '20',
      title: 'Days of Tashreeq',
      description: 'The three days following Eid al-Adha.',
      hijriDay: 11,
      hijriMonth: 12,
      significance:
          'The three days (11th, 12th, and 13th of Dhul Hijjah) following Eid al-Adha, when pilgrims complete the remaining rituals of Hajj. These are days of remembrance of Allah, eating, drinking, and celebration. The Prophet Muhammad (PBUH) described them as "days of eating, drinking, and remembering Allah." Fasting is prohibited on these days to emphasize celebration and gratitude.',
      sunnahToFollow:
          '- Recite Takbeer-e-Tashreeq after each obligatory prayer\n- Continue the spirit of celebration from Eid al-Adha\n- Share meals with family, friends, and the needy\n- Remember Allah abundantly through dhikr\n- For pilgrims: complete the remaining rituals of Hajj\n- Avoid fasting as it is prohibited on these days\n- Express gratitude for Allah\'s blessings',
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
