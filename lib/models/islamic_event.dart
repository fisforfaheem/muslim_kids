class IslamicEvent {
  final String id;
  final String title;
  final String description;
  final int hijriDay;
  final int hijriMonth;
  final String significance;
  final String sunnahToFollow;
  final bool isHoliday;
  final String imageUrl;

  IslamicEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.hijriDay,
    required this.hijriMonth,
    required this.significance,
    required this.sunnahToFollow,
    this.isHoliday = false,
    this.imageUrl = '',
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'hijriDay': hijriDay,
      'hijriMonth': hijriMonth,
      'significance': significance,
      'sunnahToFollow': sunnahToFollow,
      'isHoliday': isHoliday,
      'imageUrl': imageUrl,
    };
  }

  // Create from Firestore map
  factory IslamicEvent.fromMap(Map<String, dynamic> map) {
    return IslamicEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      hijriDay: map['hijriDay'] ?? 0,
      hijriMonth: map['hijriMonth'] ?? 0,
      significance: map['significance'] ?? '',
      sunnahToFollow: map['sunnahToFollow'] ?? '',
      isHoliday: map['isHoliday'] ?? false,
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  // Helper method to get a key in format 'day-month'
  String get dateKey => '$hijriDay-$hijriMonth';

  // Get month name
  String getMonthName() {
    final List<String> hijriMonths = [
      'Muharram',
      'Safar',
      'Rabi al-Awwal',
      'Rabi al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      'Shaban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qadah',
      'Dhu al-Hijjah',
    ];

    return hijriMonths[hijriMonth - 1];
  }

  // Format the date (e.g., "10th Muharram")
  String getFormattedDate() {
    String ordinal;
    if (hijriDay == 1 || hijriDay == 21 || hijriDay == 31) {
      ordinal = 'st';
    } else if (hijriDay == 2 || hijriDay == 22) {
      ordinal = 'nd';
    } else if (hijriDay == 3 || hijriDay == 23) {
      ordinal = 'rd';
    } else {
      ordinal = 'th';
    }

    return '$hijriDay$ordinal ${getMonthName()}';
  }
}
