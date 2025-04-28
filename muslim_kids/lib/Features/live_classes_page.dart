import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveClassesPage extends StatelessWidget {
  const LiveClassesPage({super.key});

  void _launchURL(BuildContext context, String link) async {
    if (link.isNotEmpty && Uri.tryParse(link)?.hasAbsolutePath == true) {
      final Uri url = Uri.parse(link);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch the class link')),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid class link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  const Color.fromARGB(255, 255, 244, 143), // Set background color to yellow
      appBar: AppBar(
        backgroundColor: Colors.pink[200],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
        title: Text(
          'Live Classes',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child:Text("No live classes available!",  style: TextStyle(
      fontSize: 18, // Change the text size
      color: Colors.black, // Change the text color
      fontWeight: FontWeight.bold, // Optional: Make text bold
    ),
    ));
        }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellowAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Upcoming Classes",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: snapshot.data!.docs.map((doc) {
                      var classInfo = doc.data() as Map<String, dynamic>;
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
                            Text(classInfo['topic'], 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(classInfo['teacher'], 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.green),
                                SizedBox(width: 4),
                                Text(classInfo['date'], 
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.green),
                                SizedBox(width: 4),
                                Text(classInfo['time'], 
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Center(
                              child: ElevatedButton(
                                onPressed: () => _launchURL(context, classInfo['link']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text("Join Class", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
