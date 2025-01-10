import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_page.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class AlertsPage extends StatefulWidget {
  final GlobalKey<AlertsPageState> alertsPageKey;  // Add this to receive the key

  const AlertsPage({Key? key, required this.alertsPageKey}) : super(key: key);

  @override
  AlertsPageState createState() => AlertsPageState();
}

class AlertsPageState extends State<AlertsPage> {
  Map<String, bool> alertSelection = {}; // A map to track checkbox states for each alert
  bool showActiveAlertsOnly = true;
  bool _rememberMe = false;
  final FlutterSecureStorage storage = FlutterSecureStorage();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String? actualUserID;

  // Cancel notification if the user logs out
  Future<void> cancelNotificationsOnLogout() async {
    print("User logged out, canceling scheduled notifications.");
    // You can cancel notifications here
    await flutterLocalNotificationsPlugin
        .cancelAll(); // Cancel all notifications
  }


  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _getUserID();
  }

  // Fetch the actual userID for the logged-in user
  Future<void> _getUserID() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        actualUserID =
        userDoc.data()?['userID']; // Get the actual userID from the document
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return WillPopScope(
      onWillPop: () async {
        return false; // Prevent the user from navigating back
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background container with the image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    isDarkMode
                        ? 'assets/images/dark_bg.png'
                        : 'assets/images/bg.png', // Switch background image based on dark mode
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Container with padding for the main content
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Container for the 'ALERTS' section
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black38
                          : Colors.green[800], // Set color based on dark mode
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween, // Pushes icons to opposite ends
                          children: [
                            // Notification icon on the left with extra padding
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0), // Adds padding to the left of the notification icon
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.notifications,
                                    size: 30, // Larger size for the icon
                                    color: isDarkMode ? Colors.white : Colors.white,
                                  ),
                                  const SizedBox(width: 10), // Adds some space between the icon and the text
                                  Text(
                                    'Alerts', // Your text here
                                    style: TextStyle(
                                      fontSize: 20, // Adjust the font size as needed
                                      color: isDarkMode ? Colors.white : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Filter icon on the right with extra padding
                            Padding(
                              padding: const EdgeInsets.only(right: 10.0), // Adds padding to the right of the filter icon
                              child: IconButton(
                                icon: Icon(
                                  showActiveAlertsOnly ? Icons.filter_alt : Icons.filter_alt_off,
                                  color: isDarkMode ? Colors.white : Colors.green,
                                  size: 25,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showActiveAlertsOnly = !showActiveAlertsOnly;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5.0),
                        // Wrap the inner Column in a constrained height widget
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6, // Set a fixed height for the alerts list
                          child: buildAlertList(isDarkMode),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Method to build the alert list
  Widget buildAlertList(bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No alerts available"));
        }

        if (actualUserID == null) {
          return Center(child: Text("User ID is null"));
        }

        // Filter alerts based on the toggle state
        var filteredAlerts = snapshot.data!.docs.where((alert) {
          final alertData = alert.data() as Map<String, dynamic>?; // Safely cast to Map
          if (alertData == null) return false;

          // Show all alerts if the filter is off
          if (!showActiveAlertsOnly) return true;

          // Otherwise, filter based on actualUserID value
          return alertData[actualUserID] == false;
        }).toList();

        if (filteredAlerts.isEmpty) {
          return Center(
            child: Text(
              "No alerts at the moment",
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.white, // Adjust color based on dark mode
                fontSize: 16.0, // Optional: Adjust font size
                fontWeight: FontWeight.bold, // Optional: Make text bold
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredAlerts.length,
          itemBuilder: (context, index) {
            var alert = filteredAlerts[index];
            String alertId = alert.id;

            final alertData = alert.data() as Map<String, dynamic>?; // Safely cast again
            if (alertData == null) return SizedBox.shrink();

            String title = alertData['title'] ?? 'Unknown Title';
            String? imagePath;
            if (title == 'Stay Hydrated') {
              imagePath = 'assets/images/image1.png';
            } else if (title == 'Windows') {
              imagePath = 'assets/images/image4.png';
            } else if (title == 'Proper Form') {
              imagePath = 'assets/images/image3.png';
            } else if (title == 'CLAYGO') {
              imagePath = 'assets/images/image2.png';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                height: 60.0,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white70 : Colors.white54,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    if (imagePath != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Image.asset(
                          imagePath,
                          width: 40.0,
                          height: 40.0,
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Checkbox(
                      value: alertData[actualUserID] ?? false, // Safely access the value
                      onChanged: (bool? value) async {
                        setState(() {
                          alertSelection[alertId] = value!;
                        });

                        await FirebaseFirestore.instance
                            .collection('alerts')
                            .doc(alertId)
                            .update({actualUserID!: value});
                      },
                      activeColor: Colors.green,
                      checkColor: Colors.white,
                      side: BorderSide(color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}