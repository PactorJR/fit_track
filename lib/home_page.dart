import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'settings.dart';
import 'menu.dart';
import 'cash_in.dart';
import 'profile.dart';
import 'history.dart';
import 'alerts.dart';
import 'scan_qr.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

final FlutterSecureStorage storage = FlutterSecureStorage();
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
  await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  String? payload = notificationAppLaunchDetails?.notificationResponse?.payload;
  debugPrint('App launched with payload: $payload');

  runApp(MyApp(
    selectedIndex: payload == 'open_alerts' ? 1 : 0,
    docId: null, // Default to null unless provided
  ));
}

class MyApp extends StatelessWidget {
  final int selectedIndex;
  final String? docId; // Nullable docId parameter

  const MyApp({super.key, this.selectedIndex = 0, this.docId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,  // Pass navigatorKey to the MaterialApp
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'Admin Dashboard',
        selectedIndex: selectedIndex,
        docId: docId, // Pass docId to MyAdminHomePage
      ),
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    this.selectedIndex = 0, // Default to the first tab
    this.docId, // Optional transferable data
  });

  final String? docId; // Nullable docId for optional data transfer
  final String title;
  final int selectedIndex;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<AlertsPageState> alertsPageKey = GlobalKey<AlertsPageState>();
  late int _selectedBottomNavIndex;
  int _drawerIndex = -1;
  late String _currentTitle;  // Initialize with a default title
  late bool _isDarkMode;
  final storage = FlutterSecureStorage();
  final User? user = FirebaseAuth.instance.currentUser;
  bool hasSnackbarShown = false;
  Map<String, bool> alertSelection = {
  }; // A map to track checkbox states for each alert
  bool showActiveAlertsOnly = true;
  bool _rememberMe = false;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String? actualUserID;

  final Map<int, String> _tabTitles = {
    0: 'Home',
    1: 'Alerts',
    2: 'History',
    3: 'Menu',
  };

  @override
  void initState() {
    super.initState();
    _isDarkMode = false;
    _selectedBottomNavIndex = widget.selectedIndex;
    _currentTitle = _tabTitles[_selectedBottomNavIndex] ?? 'Home';
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _checkUserNotificationStatus();  // Check if the user needs notifications
    _checkRememberMe();
    _getUserID();
    if (user != null) {
      _showLoggedInSnackbar();
    }

    // If the title is 'Alerts', set the bottom navigation index to 1
    if (_currentTitle == 'Alerts') {
      _onBottomNavTapped(1);  // Automatically select Alerts tab
    }
  }

  Future<void> _checkUserNotificationStatus() async {
    // Fetch all documents in the 'alerts' collection
    final alertDocs = await FirebaseFirestore.instance
        .collection('alerts')  // Assuming your collection is named 'alerts'
        .get();

    // Loop through each document in the collection
    for (var alertDoc in alertDocs.docs) {
      // Assuming each document has a map where each key is a userID
      // and the value is the notification status (true/false)
      final userNotifications = alertDoc.data();

      // Check if the actualuserid field exists in the document
      final actualUserIdField = userNotifications?[actualUserID];  // Replace with your actual user ID

      // If the value of the actualuserid is not true, proceed with the fetch
      if (actualUserIdField != true) {
        _fetchAlertsAndScheduleNotifications();  // Call the function only if the value is not true
        break;  // Exit the loop after the first match
      }
    }
  }

  // Cancel notification if the user logs out
  Future<void> cancelNotificationsOnLogout() async {
    print("User logged out, canceling scheduled notifications.");
    // You can cancel notifications here
    await flutterLocalNotificationsPlugin
        .cancelAll(); // Cancel all notifications
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
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);

    try {
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    debugPrint('Notification tapped with payload: ${response.payload}');

    final Map<String, int> payloadActions = {
      'open_alerts': 1,
    };

    int targetIndex = payloadActions[response.payload] ?? 0;
    debugPrint('Navigating to Users Home with selectedIndex: $targetIndex');

    // Check if the widget is still mounted before navigating
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(
            title: 'Alerts',
            selectedIndex: targetIndex, // Ensure you pass the correct docId if needed
          ),
        ),
      );
    }
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

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user is logged in.");
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    if (userData == null) {
      print("User document not found.");
      return;
    }

    final actualUserID = userData['userID'];
    final userType = userData['userType'];

    if (userType != 'Student' && userType != 'Faculty') {
      print("User is not eligible for alerts.");
      return;
    }

    if (actualUserID == null) {
      print("Actual userID not found for the current user.");
      return;
    }

    List<Future> notifications = [];

    for (var doc in alertsSnapshot.docs) {
      final alertData = doc.data();
      final durationInMinutes = alertData['duration'];
      final durationInSeconds = durationInMinutes * 60;
      final alertId = doc.id;

      if (alertData.containsKey(actualUserID)) {
        final userAlertStatus = alertData[actualUserID];
        if (userAlertStatus == true) {
          print("Alert has already been shown to the user.");
          continue;
        } else {
          notifications.add(Future.delayed(Duration(seconds: durationInSeconds), () async {
            try {
              // Update the alert document
              await FirebaseFirestore.instance.collection('alerts').doc(alertId).update({
                actualUserID: true,
              });

              // Pass the alertId to the notification method
              await _showAlertNotification(alertId, alertData['title'], alertData['desc']);

              // Schedule reset after 2 hours
              Future.delayed(Duration(hours: 2), () async {
                await FirebaseFirestore.instance.collection('alerts').doc(alertId).update({
                  actualUserID: false,
                });
              });
            } catch (e) {
              print("Error updating alert: $e");
            }
          }));
        }
      }
    }

    // Wait for all notifications to be scheduled
    await Future.wait(notifications);
  }

  Future<void> _showAlertNotification(String alertId, String title, String desc) async {
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
      alertId.hashCode, // Unique notification ID (hash of the alertId)
      title,
      desc,
      notificationDetails,
      payload: 'open_alerts',
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



  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  Future<void> _showLoggedInSnackbar() async {
    if (user == null) {
      return; // If the user is not logged in, do not show the snackbar
    }

    final userId = user!.uid; // Access uid only after confirming user is not null

    // Check if it's the first time logging in
    String? isFirstLogin = await storage.read(key: 'isFirstLogin');

    // If it's the first time, skip showing the snackbar and mark it as already shown for session
    if (isFirstLogin == null || isFirstLogin == 'true') {
      // Set isFirstLogin to false after the first login
      await storage.write(key: 'isFirstLogin', value: 'false');
      return; // Skip snackbar for first-time login
    }

    // Check if the snackbar has already been shown in the current session
    if (hasSnackbarShown) {
      return; // Skip showing the snackbar if already shown in this session
    }

    String? rememberMeValue = await storage.read(key: 'isRemembered');
    if (rememberMeValue == 'true') {
      // Fetch user details if rememberMe is true
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      String firstName = userDoc['firstName'] ?? 'First Name';
      String lastName = userDoc['lastName'] ?? 'Last Name';

      // Show Snackbar with user details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You're logged in as $firstName $lastName"),
          behavior: SnackBarBehavior.floating, // Floating snackbar
          duration: Duration(seconds: 3),
        ),
      );

      // Set the flag to true after showing the snackbar
      setState(() {
        hasSnackbarShown = true;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Center(child: Text('No user logged in'));
    }
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;


    final List<Widget> _bottomNavPages = [
      HomePage(),
      AlertsPage(alertsPageKey: alertsPageKey),
      HistoryPage(),
      MenuPage(),
    ];

    final List<Widget> _drawerPages = [
      HomePage(),
      ScanPage(),
      CashInPage(),
      ProfilePage(),
      HistoryPage(),
      AlertsPage(alertsPageKey: alertsPageKey),
      SettingsPage(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
      ),
    ];
    return WillPopScope(
      onWillPop: () async {
        return false;  // Prevent default back navigation
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.black : Colors.green.shade200, // Change to white in dark mode
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Image.asset(
                isDarkMode
                    ? 'assets/images/FitTrack_Icon_Dark.png' // Dark mode image
                    : 'assets/images/FitTrack_Icon.png',    // Light mode image
                width: 40,
                height: 40,
              ),
              SizedBox(width: 8),
              Text(
                _currentTitle,
                style: TextStyle(
                  color: isDarkMode ? Colors.green : Colors.black, // Change text color to black in dark mode
                ),
              ),
            ],
          ),
        ),
        body: _drawerIndex == -1
            ? _bottomNavPages[_selectedBottomNavIndex]
            : _drawerPages[_drawerIndex],
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.home, size: 20),
                    color: _selectedBottomNavIndex == 0 ? Colors.green : Colors.grey,
                    onPressed: () {
                      _onBottomNavTapped(0);
                    },
                  ),
                ),
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.notifications, size: 20),
                    color: _selectedBottomNavIndex == 1 ? Colors.green : Colors.grey,
                    onPressed: () {
                      _onBottomNavTapped(1);
                    },
                  ),
                ),
                SizedBox(width: 40),  // Space for FAB
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.history, size: 20),
                    color: _selectedBottomNavIndex == 2 ? Colors.green : Colors.grey,
                    onPressed: () {
                      _onBottomNavTapped(2);
                    },
                  ),
                ),
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.menu, size: 20),
                    color: _selectedBottomNavIndex == 3 ? Colors.green : Colors.grey,
                    onPressed: () {
                      _onBottomNavTapped(3);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: SizedBox(
          height: 100.0,
          width: 100.0,
          child: RawMaterialButton(
            onPressed: () {
              setState(() {});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScanPage()),
              );
            },
            shape: const CircleBorder(),
            fillColor: Colors.white,
            child: Icon(
                Icons.qr_code_scanner, size: 50, color: isDarkMode ? Colors.black : Colors.green.shade800, // Set color based on dark mode
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
      _currentTitle = _tabTitles[index] ?? 'Home';
    });
  }
}


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  User? _user;
  DocumentSnapshot? _userData;

  final imagePaths = [
    'assets/images/image1.png',
    'assets/images/image2.png',
    'assets/images/image3.png',
    'assets/images/image4.png',
  ];

  final imageDescriptions = [
    "Don't forget to drink water",
    "Clean as you go",
    "Do proper form",
    "Close windows when done",
  ];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc;
        });
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text('No user logged in'));
    }

    final userId = user.uid; // Use the actual userID
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                isDarkMode
                    ? 'assets/images/dark_bg.png'  // Dark mode background
                    : 'assets/images/bg.png',      // Light mode background
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white // White background in dark mode
                        : Colors.green.shade800.withOpacity(0.8), // Original color for light mode
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProfilePage()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.black87 : Colors.green[100], // Black in dark mode, green in light mode
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid) // Fetch the logged-in user's document
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  }
                                  if (snapshot.hasData) {
                                    // Retrieve the document data as a Map
                                    Map<String, dynamic>? _userData = snapshot.data!.data() as Map<String, dynamic>?;

                                    // Debug log for the user data

                                    // Retrieve profileIconIndex or use default and add +1
                                    int profileIconIndex = _userData != null && _userData['profileIconIndex'] != null
                                        ? (_userData['profileIconIndex'] as int) + 1
                                        : 1; // Default to 1 if profileIconIndex is null or missing

                                    // Debug log for the profileIconIndex

                                    return CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.grey[200], // Fallback background color
                                      backgroundImage: _userData != null &&
                                          _userData['profileImage'] != null &&
                                          _userData['profileImage'].isNotEmpty
                                          ? NetworkImage(_userData['profileImage']) // Display the uploaded image
                                          : AssetImage('assets/images/Icon$profileIconIndex.png') as ImageProvider, // Display the selected icon
                                      child: _userData != null &&
                                          _userData['profileImage'] != null &&
                                          _userData['profileImage'].isNotEmpty
                                          ? null // Do not display a child if the profile image is available
                                          : null, // No child if profileImage is null (AssetImage used instead)
                                    );
                                  }
                                  return Text('No user data found.');
                                },
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${_userData?.get('firstName') ?? 'First Name'} ${_userData?.get('lastName') ?? 'Last Name'}",
                                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "User ID: ${_userData?.get('userID') ?? 'Not available'}",
                                      style: TextStyle(fontSize: 17),
                                    ),
                                    Text(
                                      "User Type: ${_userData?.get('userType') ?? 'Not available'}",
                                      style: TextStyle(fontSize: 17),
                                    ),
                                    Text(
                                      "Wallet: ₱ ${_userData?.get('wallet') ?? 'Not available'}",
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20), // Space between the containers
                // New container 1 with images
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.green.shade800.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Always remember to..",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w100),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      // Swipable PageView for images with text below each image
                      SizedBox(
                        height: 400,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: imagePaths.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Display image
                                Image.asset(
                                  imagePaths[index],
                                  fit: BoxFit.cover, // Ensure the image fits well
                                  height: 300, // You can adjust the height as needed
                                ),
                                SizedBox(height: 10),
                                // Custom text below the image for each one
                                Text(
                                  imageDescriptions[index], // Use description based on index
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      // Dots indicator for the current page
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imagePaths.length,
                              (index) => AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            height: 8,
                            width: _currentIndex == index ? 16 : 8,
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
                SizedBox(height: 20), // Space between the containers
                // New container 2
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper function to build image container
  Widget _buildImageContainer(String imagePath) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}


