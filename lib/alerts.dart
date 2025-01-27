import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_page.dart';
import 'dart:async';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class AlertsPage extends StatefulWidget {
  final GlobalKey<AlertsPageState> alertsPageKey;

  const AlertsPage({Key? key, required this.alertsPageKey}) : super(key: key);

  @override
  AlertsPageState createState() => AlertsPageState();
}

class AlertsPageState extends State<AlertsPage> {
  Map<String, bool> alertSelection = {};
  bool showActiveAlertsOnly = true;
  final FlutterSecureStorage storage = FlutterSecureStorage();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String? actualUserID;

  Future<void> cancelNotificationsOnLogout() async {
    print("User logged out, canceling scheduled notifications.");
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _getUserID();
  }

  bool _isLoading = true;
  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    _getUserID();
    try {
      await Future.wait([]);
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetchAllData();
  }

  Future<void> _getUserID() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        actualUserID = userDoc.data()?['userID'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double containerHeight;

    if (screenWidth <= 409) {
      containerHeight = screenHeight * 0.65;
    } else if (screenWidth >= 410) {
      containerHeight = screenHeight * 0.65;
    } else {
      containerHeight = screenHeight * 0.70;
    }

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    isDarkMode
                        ? 'assets/images/dark_bg.png'
                        : 'assets/images/bg.png',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  padding: screenWidth <= 409
                      ? const EdgeInsets.symmetric(vertical: 8, horizontal: 10)
                      : const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: screenWidth <= 409
                            ? const EdgeInsets.all(16)
                            : const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.black38
                              : Colors.green[800],
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: screenWidth <= 409
                                      ? const EdgeInsets.only(left: 8)
                                      : const EdgeInsets.only(left: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.notifications,
                                        size: screenWidth <= 409 ? 24 : 35,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: screenWidth <= 409 ? 8 : 15),
                                      Text(
                                        'Alerts',
                                        style: TextStyle(
                                          fontSize: screenWidth <= 409 ? 15 : 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: screenWidth <= 409
                                      ? const EdgeInsets.only(right: 8)
                                      : const EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    icon: Icon(
                                      showActiveAlertsOnly ? Icons.filter_alt : Icons.filter_alt_off,
                                      color: isDarkMode ? Colors.white : Colors.green,
                                      size: screenWidth <= 409 ? 24 : 30,
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
                            SizedBox(height: screenWidth < 360 ? 4 : 5),
                            SizedBox(
                              height: containerHeight,
                              child: buildAlertList(isDarkMode),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAlertList(bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No scheduled alerts available"));
          }

          if (actualUserID == null) {
            return const Center(child: Text("User ID is null"));
          }

          var filteredAlerts = snapshot.data!.docs.where((alert) {
            final alertData = alert.data() as Map<String, dynamic>?;
            if (alertData == null) return false;

            if (!showActiveAlertsOnly) return true;

            return alertData[actualUserID] == false;
          }).toList();

          if (filteredAlerts.isEmpty) {
            return Center(
              child: Text(
                "No Scheduled Alerts at the Moment",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: filteredAlerts.length,
            itemBuilder: (context, index) {
              var alert = filteredAlerts[index];
              String alertId = alert.id;

              final alertData = alert.data() as Map<String, dynamic>?;
              if (alertData == null) return const SizedBox.shrink();

              String title = alertData['title'] ?? 'Unknown Title';
              String? imagePath;
              if (title == 'Stay Hydrated') {
                imagePath = 'assets/images/image1.gif';
              } else if (title == 'Windows') {
                imagePath = 'assets/images/image4.gif';
              } else if (title == 'Proper Form') {
                imagePath = 'assets/images/image3.gif';
              } else if (title == 'CAYGO') {
                imagePath = 'assets/images/image2.gif';
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
                              color: isDarkMode ? Colors.white : Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Checkbox(
                        value: alertData[actualUserID] ?? true,
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
                        side: const BorderSide(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
