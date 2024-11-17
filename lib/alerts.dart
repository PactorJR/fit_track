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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const AlertsPage(),
    );
  }
}

class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  Map<String, bool> alertSelection = {
  }; // A map to track checkbox states for each alert
  bool showActiveAlertsOnly = true;
  bool _rememberMe = false;
  final FlutterSecureStorage storage = FlutterSecureStorage();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String? actualUserID;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _checkRememberMe();
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

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
        android: androidSettings);

    // Initialize with callback for when notification is tapped
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == 'open_alerts') {
          // Ensure that navigation happens using Navigator context
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
            const MyHomePage(title: 'Alerts'), // Push the widget, not the state
          ));
        }
      },
    );
  }

  Future<void> _checkRememberMe() async {
    String? value = await storage.read(key: 'isRemembered');
    if (value == 'true') {
      setState(() {
        _rememberMe = true;
      });
      _fetchAlertsAndScheduleNotifications();
    }
  }

  Future<void> _fetchAlertsAndScheduleNotifications() async {
    final alertsCollection = FirebaseFirestore.instance.collection('alerts');
    final alertsSnapshot = await alertsCollection.get();

    // Get the current Firebase user
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user is logged in.");
      return;
    }

    // Retrieve the actual userID from the 'users' collection
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(
        user.uid).get();
    final actualUserID = userDoc.data()?['userID'];

    if (actualUserID == null) {
      print("Actual userID not found for the current user.");
      return;
    }

    for (var doc in alertsSnapshot.docs) {
      final alertData = doc.data();
      final durationInMinutes = alertData['duration']; // Duration in minutes
      final durationInSeconds = durationInMinutes * 60; // Convert to seconds
      final alertId = doc.id; // Document ID for update operations

      // Check if the actualUserID field exists in the alert document
      if (!alertData.containsKey(actualUserID)) {
        // Add the userID field with an initial value of `false`
        await FirebaseFirestore.instance.collection('alerts')
            .doc(alertId)
            .update({
          actualUserID: false,
        });
      }

      // Schedule the notification to be shown after the specified duration
      Future.delayed(Duration(seconds: durationInSeconds), () async {
        // Check if the user is still logged in before proceeding
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          print("User logged out, stopping alerts.");
          return;
        }

        // Set the actual userID as a field with a boolean value for active status
        await FirebaseFirestore.instance.collection('alerts')
            .doc(alertId)
            .update({
          actualUserID: true,
          // Set the actual userID as the field and true as the value
        });

        // Show the notification
        _showAlertNotification(alertData['title'], alertData['desc']);

        // Schedule a 2-hour delay to reset the user's boolean to false
        Future.delayed(Duration(hours: 2), () async {
          // Check again if the user is still logged in
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await FirebaseFirestore.instance.collection('alerts')
                .doc(alertId)
                .update({
              actualUserID: false,
              // Set the actual userID field to false after 2 hours
            });
          }
        });
      });
    }
  }

  Future<void> _showAlertNotification(String title, String desc) async {
    final largeIconPath = await _getCircularLargeIconPath(); // A method to get the circular image path

    final androidDetails = AndroidNotificationDetails(
      'alerts_channel', // Channel ID
      'Alerts Notifications', // Channel Name
      icon: '@drawable/app_icon',
      // Small icon resource from drawable (not circular)
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      // Show the timestamp of the notification
      styleInformation: BigTextStyleInformation(
        desc, // Expanded text content for "show more"
        contentTitle: title, // Title in the expanded view
        summaryText: 'Tap for more details', // Optional summary text
      ),
      largeIcon: FilePathAndroidBitmap(
          largeIconPath), // Set large circular image/icon
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      desc,
      notificationDetails,
      payload: 'open_alerts', // Payload to identify this notification
    );
  }

  Future<String> _getCircularLargeIconPath() async {
    // Load image from assets
    final ByteData data = await rootBundle.load('assets/images/Icon_Notif.png');
    final Uint8List bytes = data.buffer.asUint8List();

    // Decode to ui.Image
    final ui.Image image = await _loadImage(bytes);

    // Convert to circular ui.Image
    final ui.Image circularImage = await _createCircularImage(image);

    // Save and return file path
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File('${tempDir.path}/Icon_Notif_Circular.png');
    await file.writeAsBytes(await _encodePng(circularImage));
    return file.path;
  }

  Future<ui.Image> _loadImage(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  Future<ui.Image> _createCircularImage(ui.Image sourceImage) async {
    final int size = sourceImage.width < sourceImage.height
        ? sourceImage.width
        : sourceImage.height;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

    final Paint paint = Paint()
      ..isAntiAlias = true;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    paint.blendMode = BlendMode.srcIn;
    canvas.drawImageRect(
      sourceImage,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      paint,
    );

    final ui.Image circularImage = await recorder.endRecording().toImage(
        size, size);
    return circularImage;
  }


// Encode the ui.Image into a PNG
  Future<Uint8List> _encodePng(ui.Image image) async {
    final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to convert image to PNG format');
    }
    return byteData.buffer.asUint8List();
  }


  @override
  Widget build(BuildContext context) {
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
                  image: AssetImage('assets/images/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Main content over the background
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.green[800],
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                    Icons.notifications, color: Colors.green),
                                const SizedBox(width: 8.0),
                                const Text(
                                  'ALERTS',
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 18),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                showActiveAlertsOnly ? Icons.filter_alt : Icons
                                    .filter_alt_off,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                setState(() {
                                  showActiveAlertsOnly = !showActiveAlertsOnly;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Expanded(
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance.collection('alerts')
                          .snapshots(),
                      builder: (context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData || actualUserID == null) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final alerts = snapshot.data!.docs.map((alert) async {
                          final alertData = alert.data() as Map<String,
                              dynamic>?;
                          final alertId = alert.id;

                          if (alertData != null &&
                              !alertData.containsKey(actualUserID)) {
                            await FirebaseFirestore.instance.collection(
                                'alerts').doc(alertId).update({
                              actualUserID!: false,
                            });
                          }

                          return alert;
                        }).toList();

                        var filteredAlerts = snapshot.data!.docs.where((alert) {
                          final alertData = alert.data() as Map<String,
                              dynamic>?;
                          return alertData != null && (showActiveAlertsOnly
                              ? alertData[actualUserID!] == true
                              : true);
                        }).toList();

                        return ListView.builder(
                          itemCount: filteredAlerts.length,
                          itemBuilder: (context, index) {
                            var alert = filteredAlerts[index];
                            String alertId = alert.id;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              height: 60.0,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        alert['title'],
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  Checkbox(
                                    value: alertSelection[alertId] ?? false,
                                    onChanged: (bool? value) async {
                                      setState(() {
                                        alertSelection[alertId] = value!;
                                      });

                                      if (value == true) {
                                        await FirebaseFirestore.instance
                                            .collection('alerts')
                                            .doc(alertId)
                                            .update({actualUserID!: false});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
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
}