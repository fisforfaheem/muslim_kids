import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:muslim_kids/local_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherHomePage extends StatefulWidget {
  final String email;
  const TeacherHomePage({super.key, required this.email});

  @override
  TeacherHomePageState createState() => TeacherHomePageState();
}

class TeacherHomePageState extends State<TeacherHomePage> {
  void addClassToFirebase(String teacher, String topic, String date, String time, String link) {
  FirebaseFirestore.instance.collection('classes').add({
    'user':widget.email,
    'teacher': teacher,
    'topic': topic,
    'date': date,
    'time': time,
    'link': link,
    'timestamp': FieldValue.serverTimestamp(),
  }).then((value) async {
     DateTime classDateTime = DateFormat('yyyy-MM-dd hh:mm a').parse('$date $time');
    if (classDateTime.isAfter(DateTime.now())){
    Fluttertoast.showToast(
      msg: "Class scheduled successfully!",
      backgroundColor: Colors.green,
      textColor: Colors.black,
      fontSize: 18.0,
      toastLength: Toast.LENGTH_SHORT,
    );}   

    if (classDateTime.isAfter(DateTime.now())) {
      await LocalNotificationService.showNotification(
        id: value.id.hashCode, // Unique ID for each notification
        title: "Upcoming Class Reminder",
        body: "Your class on '$topic' with $teacher will be on $date at $time!",
      );
    }//for scheduled class notification
  }).catchError((error) {
    Fluttertoast.showToast(
      msg: "Error scheduling class: $error",
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 18.0,
      toastLength: Toast.LENGTH_SHORT,
    );
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "As-Salaam-Alaikum",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage('assets/teacher.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: showScheduleClassDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  "Schedule Class",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upcoming Classes",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              StreamBuilder(
  stream: FirebaseFirestore.instance
      .collection('classes')
      .where('user', isEqualTo: widget.email) 
      .orderBy('timestamp', descending: true)
      .snapshots(),
  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData) {
      return Center(child: CircularProgressIndicator());
    }

    var classes = snapshot.data!.docs;

    // Get the current date and time
    DateTime now = DateTime.now();

    // Filter out expired classes
    for (var classDoc in classes) {
      try {
        String dateStr = classDoc['date']; // Format: yyyy-MM-dd
        String timeStr = classDoc['time']; // Format: HH:mm AM/PM

        // Convert date and time to DateTime object
        DateTime classDateTime = DateFormat('yyyy-MM-dd hh:mm a').parse('$dateStr $timeStr');

        // If class time has passed, delete from Firebase
        if (classDateTime.isBefore(now)) {
          FirebaseFirestore.instance.collection('classes').doc(classDoc.id).delete();
        }
      } catch (e) {
        debugPrint("Error parsing date/time: $e");
      }
    }

    // Remove deleted classes from the list
    classes.removeWhere((classDoc) {
      try {
        String dateStr = classDoc['date'];
        String timeStr = classDoc['time'];
        DateTime classDateTime = DateFormat('yyyy-MM-dd hh:mm a').parse('$dateStr $timeStr');
        return classDateTime.isBefore(now);
      } catch (e) {
        return false;
      }
    });

    if (classes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No class scheduled yet! If you want to schedule Islamic lesson click "Schedule Class" button.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        var classData = classes[index];
        return ClassCard(
          title: classData['topic'],
          teacher: classData['teacher'],
          date: classData['date'],
          time: classData['time'],
          link: classData['link'],
          onCancel: () =>
              FirebaseFirestore.instance.collection('classes').doc(classData.id).delete(),
        );
      },
    );
  },
),
            ],
          ),
        ),
      ],
    )
 )
)
);
}


  void showScheduleClassDialog() {
    final TextEditingController teacherController = TextEditingController();
    final TextEditingController topicController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final TextEditingController linkController = TextEditingController();

    Future<void> selectDate() async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
      );
      if (pickedDate != null && mounted) {
        setState(() {
          dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        });
      }
    }

    Future<void> selectTime() async {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          timeController.text = pickedTime.format(context);
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: Text("Schedule New Class", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: teacherController, decoration: InputDecoration(labelText: "Teacher Name")),
              TextField(controller: topicController, decoration: InputDecoration(labelText: "Topic")),
              TextField(controller: dateController, decoration: InputDecoration(labelText: "Date", suffixIcon: IconButton(icon: Icon(Icons.calendar_today), onPressed: selectDate)), readOnly: true),
              TextField(controller: timeController, decoration: InputDecoration(labelText: "Time", suffixIcon: IconButton(icon: Icon(Icons.access_time), onPressed: selectTime)), readOnly: true),
              TextField(controller: linkController, decoration: InputDecoration(labelText: "Class Link")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold))),
            ElevatedButton(onPressed: () {
              addClassToFirebase(teacherController.text, topicController.text, dateController.text, timeController.text, linkController.text);
              Navigator.pop(context);
            }, child: Text("Submit")),
          ],
        );
      },
    );
  }
}

class ClassCard extends StatelessWidget {
  final String title, teacher, date, time, link;
  final VoidCallback onCancel;

  const ClassCard({
    super.key,
    required this.title,
    required this.teacher,
    required this.date,
    required this.time,
    required this.link,
    required this.onCancel,
  });

  void _launchURL() async {
  final Uri url = Uri.parse(link);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $link');
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(teacher, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.green),
              SizedBox(width: 4),
              Text(date, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.green),
              SizedBox(width: 4),
              Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _launchURL,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text("Join Class", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: onCancel,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("Cancel Class", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


