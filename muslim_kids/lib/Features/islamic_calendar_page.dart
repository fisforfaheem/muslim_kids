import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:muslim_kids/models/islamic_event.dart';
import 'package:muslim_kids/services/islamic_calendar_service.dart';
import 'package:muslim_kids/screens/event_detail_screen.dart';

class IslamicCalendarPage extends StatefulWidget {
  const IslamicCalendarPage({super.key});

  @override
  IslamicCalendarPageState createState() => IslamicCalendarPageState();
}

class IslamicCalendarPageState extends State<IslamicCalendarPage> {
  final IslamicCalendarService _calendarService = IslamicCalendarService();
  DateTime _selectedDay = DateTime.now();
  HijriCalendar _selectedHijriDay = HijriCalendar.now();
  DateTime _focusedDay = DateTime.now();
  Map<String, IslamicEvent> _eventsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final eventsMap = await _calendarService.getEventsMap();
      setState(() {
        _eventsMap = eventsMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedHijriDay = HijriCalendar.fromDate(selectedDay);
    });

    String hijriKey = "${_selectedHijriDay.hDay}-${_selectedHijriDay.hMonth}";
    if (_eventsMap.containsKey(hijriKey)) {
      _showEventDetails(_eventsMap[hijriKey]!);
    }
  }

  void _showEventDetails(IslamicEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 244, 143),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 88, 144),
        title: const Text(
          'Islamic Calendar',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(),
        ),
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDateHeader(),
                _buildMonthNavigator(),
                // Main calendar area - wrapped in Expanded to handle overflow
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildCalendar(),
                  ),
                ),
                _buildUpcomingEvents(),
              ],
            ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 255, 129, 171),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hijri Date",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                _selectedHijriDay.toFormat("d MMMM yyyy"),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Gregorian Date",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('MMMM d, yyyy').format(_selectedDay),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _previousMonth,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text("< Previous",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedDay),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed: _nextMonth,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text("Next >",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime(2000, 1, 1),
      lastDay: DateTime(2100, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,
      calendarFormat: CalendarFormat.month,
      headerVisible: false,
      availableGestures: AvailableGestures.all,
      rowHeight: 65, // Reduced height to prevent overflow
      daysOfWeekHeight: 30, // Reduced height of day headers
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        weekendStyle: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
        decoration: BoxDecoration(
            color: Color(0xFFFFF8D9)), // Subtle background for day names
      ),
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
        cellMargin: EdgeInsets.all(1), // Reduced margins for more space
        defaultTextStyle: TextStyle(fontSize: 0), // Hide default text
        weekendTextStyle: TextStyle(fontSize: 0), // Hide default text
        selectedTextStyle: TextStyle(fontSize: 0), // Hide default text
        todayTextStyle: TextStyle(fontSize: 0), // Hide default text
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          return _buildCalendarCell(date, false, false);
        },
        selectedBuilder: (context, date, _) {
          return _buildCalendarCell(date, true, false);
        },
        todayBuilder: (context, date, _) {
          return _buildCalendarCell(date, false, true);
        },
        outsideBuilder: (context, date, _) {
          return const SizedBox.shrink(); // Hide outside days
        },
        disabledBuilder: (context, date, _) {
          return const SizedBox.shrink(); // Hide disabled days
        },
      ),
    );
  }

  Widget _buildCalendarCell(DateTime date, bool isSelected, bool isToday) {
    // Get Hijri date
    HijriCalendar hijriDate = HijriCalendar.fromDate(date);
    String hijriKey = "${hijriDate.hDay}-${hijriDate.hMonth}";

    // Check if this is a significant Islamic day
    bool isSignificant = _eventsMap.containsKey(hijriKey);

    // Cell background color based on state
    Color? backgroundColor;
    if (isSelected) {
      backgroundColor = Colors.pink;
    } else if (isSignificant) {
      backgroundColor = Colors.amber[100];
    } else if (isToday) {
      backgroundColor = Colors.blue[100];
    } else {
      backgroundColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6.0),
        border: isToday && !isSelected
            ? Border.all(color: Colors.blue, width: 1.5)
            : null,
        boxShadow: [
          if (isSignificant && !isSelected)
            const BoxShadow(
              color: Colors.amber,
              blurRadius: 1,
              spreadRadius: 0.5,
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gregorian day number
          Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : isSignificant
                      ? Colors.amber[800]
                      : isToday
                          ? Colors.blue[800]
                          : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          // Hijri day number in a more visible circle
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.3)
                  : isSignificant
                      ? Colors.amber.withOpacity(0.2)
                      : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Text(
              hijriDate.hDay.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isSignificant
                        ? Colors.amber[800]
                        : Colors.grey[700],
              ),
            ),
          ),
          // Star icon for significant days
          if (isSignificant && !isSelected)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.star,
                color: Colors.amber,
                size: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    List<IslamicEvent> upcomingEvents = [];
    HijriCalendar today = HijriCalendar.now();

    // Find the next 2 events from today (reduced from 3 to fit better)
    for (var month = today.hMonth; month <= 12; month++) {
      for (var day = (month == today.hMonth ? today.hDay : 1);
          day <= 30;
          day++) {
        String key = "$day-$month";
        if (_eventsMap.containsKey(key)) {
          upcomingEvents.add(_eventsMap[key]!);
          if (upcomingEvents.length >= 2) break;
        }
      }
      if (upcomingEvents.length >= 2) break;
    }

    // If we didn't find 2 events, look in next year
    if (upcomingEvents.length < 2) {
      for (var month = 1; month < today.hMonth; month++) {
        for (var day = 1; day <= 30; day++) {
          String key = "$day-$month";
          if (_eventsMap.containsKey(key)) {
            upcomingEvents.add(_eventsMap[key]!);
            if (upcomingEvents.length >= 2) break;
          }
        }
        if (upcomingEvents.length >= 2) break;
      }
    }

    if (upcomingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_note, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Upcoming Islamic Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90, // Reduced height to save space
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: upcomingEvents.length,
              itemBuilder: (context, index) {
                final event = upcomingEvents[index];
                return GestureDetector(
                  onTap: () => _showEventDetails(event),
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          event.isHoliday ? Colors.amber[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: event.isHoliday ? Colors.amber : Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: event.isHoliday
                                  ? Colors.amber[700]
                                  : Colors.blue[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.getFormattedDate(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: event.isHoliday
                                    ? Colors.amber[700]
                                    : Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 5), // Extra padding at bottom for safety
        ],
      ),
    );
  }
}
