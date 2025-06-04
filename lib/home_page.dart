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
    docId: null,
  ));
}

class MyApp extends StatelessWidget {
  final int selectedIndex;
  final String? docId;

  const MyApp({super.key, this.selectedIndex = 0, this.docId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'Home',
        selectedIndex: selectedIndex,
        docId: docId,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    this.selectedIndex = 0,
    this.docId,
    this.cameFromScanPage = false,
  });

  final String? docId;
  final String title;
  final int selectedIndex;
  final bool cameFromScanPage;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<AlertsPageState> alertsPageKey = GlobalKey<AlertsPageState>();
  late int _selectedBottomNavIndex;
  int _drawerIndex = -1;
  late String _currentTitle;
  late bool _isDarkMode;
  final storage = FlutterSecureStorage();
  final User? user = FirebaseAuth.instance.currentUser;
  bool hasSnackbarShown = false;
  Map<String, bool> alertSelection = {};
  bool showActiveAlertsOnly = true;
  bool _rememberMe = false;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String? actualUserID;
  late Timer _notificationTimer;

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
    _checkUserNotificationStatus();
    _startNotificationStatusChecker();
    if (user != null) {
      _showLoggedInSnackbar(cameFromScanPage: widget.cameFromScanPage);
    }
    if (_currentTitle == 'Alerts') {
      _onBottomNavTapped(1);
    }
  }

  @override
  void dispose() {
    _notificationTimer.cancel();
    super.dispose();
  }

  void _startNotificationStatusChecker() {
    _notificationTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkUserNotificationStatus();
      print("every 1 minute");
    });
  }

  Future<void> _checkUserNotificationStatus() async {
    final currentUserID = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserID == null) {
      print("No user is logged in");
      return;
    }

    final userDocSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserID)
        .get();

    if (!userDocSnapshot.exists) {
      print("User document not found");
      return;
    }

    final userDoc = userDocSnapshot.data();
    final actualUserID = userDoc?['userID'];

    if (actualUserID == null) {
      print("UserID not found in user document");
      return;
    }

    final alertDocs = await FirebaseFirestore.instance
        .collection('alerts')
        .get();

    for (var alertDoc in alertDocs.docs) {
      final userNotifications = alertDoc.data();
      final alertTitle = userNotifications?['title'];
      final actualUserIDField = userNotifications?[actualUserID];
      final lastUpdatedField = 'lastUpdated$actualUserID';
      final lastUpdatedCurrentUserIDField = userNotifications?[lastUpdatedField];
      final durationField = 'duration$actualUserID';

      int duration = 0;
      if (alertTitle == "Stay Hydrated") {
        duration = 1;
      } else if (alertTitle == "Proper Form") {
        duration = 2;
      } else if (alertTitle == "Windows") {
        duration = 3;
      } else if (alertTitle == "CAYGO") {
        duration = 4;
      }

      if (actualUserIDField == null || lastUpdatedCurrentUserIDField == null) {
        await FirebaseFirestore.instance
            .collection('alerts')
            .doc(alertDoc.id)
            .update({
          actualUserID: false,
          lastUpdatedField: FieldValue.serverTimestamp(),
          durationField: duration,
        });

        _fetchAlertsAndScheduleNotifications();
      } else {
        if (actualUserIDField == true && lastUpdatedCurrentUserIDField != null) {
          final currentTimestamp = DateTime.now();
          final lastUpdatedTimestamp = (lastUpdatedCurrentUserIDField as Timestamp).toDate();
          final difference = currentTimestamp.difference(lastUpdatedTimestamp);

          if (difference.inMinutes > 1440) {
            await FirebaseFirestore.instance
                .collection('alerts')
                .doc(alertDoc.id)
                .update({
              actualUserID: false,
              lastUpdatedField: FieldValue.serverTimestamp(),
            });

            _fetchAlertsAndScheduleNotifications();
          }
        }
      }
    }
  }

  Future<void> cancelNotificationsOnLogout() async {
    print("User logged out, canceling scheduled notifications.");
    await flutterLocalNotificationsPlugin.cancelAll();
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
      final alertId = doc.id;
      final durationField = 'duration$actualUserID';
      final durationInMinutes = alertData[durationField] ?? 0;
      final durationInSeconds = durationInMinutes * 60;

      if (alertData.containsKey(actualUserID)) {
        final userAlertStatus = alertData[actualUserID];
        if (userAlertStatus == true) {
          print("Alert has already been shown to the user.");
          continue;
        } else {
          notifications.add(Future.delayed(Duration(seconds: durationInSeconds), () async {
            try {
              await FirebaseFirestore.instance.collection('alerts').doc(alertId).update({
                actualUserID: true,
              });

              await _showAlertNotification(alertId, alertData['title'], alertData['desc']);
            } catch (e) {
              print("Error updating alert: $e");
            }
          }));
        }
      }
    }

    await Future.wait(notifications);
  }



  Future<void> _showAlertNotification(String alertId, String title, String desc) async {
    final largeIconPath = await _getCircularLargeIconPath();

    final androidDetails = AndroidNotificationDetails(
      'alerts_channel',
      'Alerts Notifications',
      icon: '@drawable/app_icon',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(
        desc,
        contentTitle: title,
        summaryText: 'Tap for more details',
      ),
      largeIcon: FilePathAndroidBitmap(largeIconPath),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      alertId.hashCode,
      title,
      desc,
      notificationDetails,
      payload: 'open_alerts',
    );
  }

  Future<String> _getCircularLargeIconPath() async {
    final ByteData data = await rootBundle.load('assets/images/Icon_Notif.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Image image = await _loadImage(bytes);
    final ui.Image circularImage = await _createCircularImage(image);
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
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

    final Paint paint = Paint()..isAntiAlias = true;
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

    final ui.Image circularImage = await recorder.endRecording().toImage(size, size);
    return circularImage;
  }

  Future<Uint8List> _encodePng(ui.Image image) async {
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
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

  Future<void> _showLoggedInSnackbar({bool cameFromScanPage = false}) async {
    if (user == null || cameFromScanPage) {
      return;
    }

    final userId = user!.uid;

    try {
      String? isFirstLogin = await storage.read(key: 'isFirstLogin');
      if (isFirstLogin == null || isFirstLogin == 'true') {
        await storage.write(key: 'isFirstLogin', value: 'false');
        return;
      }

      if (hasSnackbarShown) {
        return;
      }

      String? rememberMeValue = await storage.read(key: 'isRemembered');
      if (rememberMeValue == 'true') {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        String firstName = userDoc['firstName'] ?? 'First Name';
        String lastName = userDoc['lastName'] ?? 'Last Name';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You're logged in the App as $firstName $lastName"),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );

        setState(() {
          hasSnackbarShown = true;
        });
      }
    } catch (e) {
      await storage.deleteAll();
      print("Error occurred in storage: $e");
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double containerHeight;
    double containerWidth;

    double iconSize = screenWidth * 0.06;
    double textSize = screenWidth * 0.02;
    double bottomAppBarHeight = screenWidth * 0.18;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.black : Colors.green.shade200,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Image.asset(
                isDarkMode ? 'assets/images/FitTrack_Icon_Dark.png' : 'assets/images/FitTrack_Icon.png',
                width: 40,
                height: 40,
              ),
              SizedBox(width: 8),
              Text(
                _currentTitle,
                style: TextStyle(
                  fontFamily: 'Arial',
                  color: isDarkMode ? Colors.green : Colors.white,
                ),
              ),
            ],
          ),
        ),
        body: _drawerIndex == -1
            ? _bottomNavPages[_selectedBottomNavIndex]
            : _drawerPages[_drawerIndex],
        bottomNavigationBar: BottomAppBar(
          height: bottomAppBarHeight,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _onBottomNavTapped(0),
                      child: Icon(
                        Icons.home,
                        size: iconSize,
                        color: _selectedBottomNavIndex == 0 ? Colors.green : Colors.grey,
                      ),
                    ),
                    Text(
                      'Home',
                      style: TextStyle(
                        color: _selectedBottomNavIndex == 0 ? Colors.green : Colors.grey,
                        fontSize: textSize,
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _onBottomNavTapped(1),
                      child: Icon(
                        Icons.notifications,
                        size: iconSize,
                        color: _selectedBottomNavIndex == 1 ? Colors.green : Colors.grey,
                      ),
                    ),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        color: _selectedBottomNavIndex == 1 ? Colors.green : Colors.grey,
                        fontSize: textSize,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 60),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _onBottomNavTapped(2),
                      child: Icon(
                        Icons.history,
                        size: iconSize,
                        color: _selectedBottomNavIndex == 2 ? Colors.green : Colors.grey,
                      ),
                    ),
                    Text(
                      'History',
                      style: TextStyle(
                        color: _selectedBottomNavIndex == 2 ? Colors.green : Colors.grey,
                        fontSize: textSize,
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _onBottomNavTapped(3),
                      child: Icon(
                        Icons.menu,
                        size: iconSize,
                        color: _selectedBottomNavIndex == 3 ? Colors.green : Colors.grey,
                      ),
                    ),
                    Text(
                      'Menu',
                      style: TextStyle(
                        color: _selectedBottomNavIndex == 3 ? Colors.green : Colors.grey,
                        fontSize: textSize,
                      ),
                    ),
                  ],
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
              Icons.qr_code_scanner,
              size: 50,
              color: isDarkMode ? Colors.black : Colors.green.shade800,
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
  bool _isLoading = true;
  late Timer _userDataTimer;


  @override
  void dispose() {
    _userDataTimer.cancel();
    super.dispose();
  }

  void _startUserDataTimer() {
    _userDataTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _fetchUserData();
      print("every 2 seconds");
    });
  }

  final imagePaths = [
    'assets/images/image1.gif',
    'assets/images/image2.gif',
    'assets/images/image3.gif',
    'assets/images/image4.gif',
  ];

  final imageDescriptions = [
    "Stay Hydrated!",
    "Clean as you go",
    "Do proper form",
    "Close windows when done",
  ];

  @override
  void initState() {
    super.initState();
    _startUserDataTimer();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    _fetchUserData();
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
    bool isDarkMode = Provider
        .of<ThemeProvider>(context)
        .isDarkMode;
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text('No user logged in'));
    }

    final userId = user.uid;
    return Stack(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Container(
                      height: MediaQuery
                          .of(context)
                          .size
                          .width <= 409 ? 190 : 215,
                      width: MediaQuery
                          .of(context)
                          .size
                          .width <= 409 ? 390 : 390,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20.0, horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black38
                            : Colors.green.shade800.withOpacity(0.8),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ProfilePage()),
                              );
                            },
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(
                                        FirebaseAuth.instance.currentUser!.uid)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }
                                      if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      }
                                      if (snapshot.hasData) {
                                        Map<String,
                                            dynamic>? _userData = snapshot.data!
                                            .data() as Map<String, dynamic>?;

                                        int profileIconIndex = _userData !=
                                            null &&
                                            _userData['profileIconIndex'] !=
                                                null
                                            ? (_userData['profileIconIndex'] as int) +
                                            1
                                            : 1;

                                        double devicePixelRatio = MediaQuery
                                            .of(context)
                                            .devicePixelRatio;
                                        double screenWidth = MediaQuery
                                            .of(context)
                                            .size
                                            .width;
                                        double avatarRadius;

                                        if (screenWidth <= 409) {
                                          avatarRadius = 30.0;
                                        } else if (screenWidth >= 410) {
                                          avatarRadius = 40.0;
                                        } else {
                                          avatarRadius = 50.0;
                                        }

                                        return CircleAvatar(
                                          radius: avatarRadius,
                                          backgroundColor: Colors.grey[200],
                                          backgroundImage: _userData != null &&
                                              _userData['profileImage'] !=
                                                  null &&
                                              _userData['profileImage']
                                                  .isNotEmpty
                                              ? NetworkImage(
                                              _userData['profileImage'])
                                              : AssetImage(
                                              'assets/images/Icon$profileIconIndex.png') as ImageProvider,
                                        );
                                      }
                                      return Text('No user data found.');
                                    },
                                  ),
                                  SizedBox(width: 20),
                                  SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            double screenWidth = MediaQuery
                                                .of(context)
                                                .size
                                                .width;
                                            double firstNameFontSize = screenWidth <=
                                                409 ? 24 : 30;
                                            double otherFontSize = screenWidth <=
                                                409 ? 14 : 17;

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Text(
                                                  "${_userData?.get(
                                                      'firstName') ??
                                                      'First Name'} ${_userData
                                                      ?.get('lastName') ??
                                                      'Last Name'}",
                                                  style: TextStyle(
                                                    fontSize: firstNameFontSize,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,),
                                                ),
                                                Text(
                                                  "User ID: ${_userData?.get(
                                                      'userID') ??
                                                      'Not available'}",
                                                  style: TextStyle(
                                                    fontSize: otherFontSize,
                                                    color: Colors.white,),
                                                ),
                                                Text(
                                                  "User Type: ${_userData?.get(
                                                      'userType') ??
                                                      'Not available'}",
                                                  style: TextStyle(
                                                    fontSize: otherFontSize,
                                                    color: Colors.white,),
                                                ),
                                                Text(
                                                  "Wallet: ₱ ${_userData?.get(
                                                      'wallet') ??
                                                      'Not available'}",
                                                  style: TextStyle(
                                                    fontSize: otherFontSize,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,),
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      "Status: ",
                                                      style: TextStyle(
                                                        fontSize: 17,
                                                        fontWeight: FontWeight
                                                            .bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Text(
                                                      _userData?.get(
                                                          'loggedStatus') ==
                                                          false
                                                          ? 'Outside'
                                                          : 'Inside',
                                                      style: TextStyle(
                                                        fontSize: 17,
                                                        fontWeight: FontWeight
                                                            .bold,
                                                        color: _userData?.get(
                                                            'loggedStatus') ==
                                                            false
                                                            ? Colors.red
                                                            : Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
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
                    SizedBox(height: 20),
                    Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width <= 409 ? 390 : 390,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20.0, horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black38 : Colors.green.shade800
                            .withOpacity(0.8),
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
                            style: TextStyle(color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w100),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            height: MediaQuery
                                .of(context)
                                .size
                                .width <= 409 ? 250 : 355,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: imagePaths.length,
                              onPageChanged: (index) {
                                _currentIndex = index;
                                if (mounted) {
                                  setState(() {
                                    _currentIndex = index;
                                  });
                                }
                              },
                              itemBuilder: (context, index) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      imagePaths[index],
                                      fit: BoxFit.cover,
                                      height: MediaQuery
                                          .of(context)
                                          .size
                                          .width <= 409 ? 200 : 300,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      imageDescriptions[index],
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              imagePaths.length,
                                  (index) =>
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
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
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


