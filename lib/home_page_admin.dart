import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'menu_admin.dart';
import 'history_admin.dart';
import 'alerts_admin.dart';
import 'scan_qr.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'graphs_admin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'count_per_day.dart';
import 'count_per_month.dart';
import 'users_admin.dart';
import 'income_admin.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterSecureStorage storage = FlutterSecureStorage();

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
    selectedIndex: payload == 'new_user' ? 1 : 0,
    docId: null,
  ));
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

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
      home: MyAdminHomePage(
        title: 'Admin Dashboard',
        selectedIndex: selectedIndex,
        docId: docId,
      ),
    );
  }
}

class MyAdminHomePage extends StatefulWidget {
  const MyAdminHomePage({
    super.key,
    required this.title,
    this.selectedIndex = 0,
    this.docId,
  });

  final String? docId;
  final String title;
  final int selectedIndex;

  @override
  State<MyAdminHomePage> createState() => _MyHomePageState();
}

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._privateConstructor();

  factory NotificationManager() {
    return _instance;
  }

  NotificationManager._privateConstructor();

  Set<int> shownNotificationIds = Set();

  Future<void> loadShownNotificationIds() async {
    String? storedIds = await storage.read(key: 'shownNotificationIds');
    if (storedIds != null) {
      shownNotificationIds = Set<int>.from(storedIds.split(',').map((id) => int.parse(id)));
    }
  }

  Future<void> saveShownNotificationIds() async {
    await storage.write(key: 'shownNotificationIds', value: shownNotificationIds.join(','));
  }
}

class _MyHomePageState extends State<MyAdminHomePage> {

  late int _selectedBottomNavIndex;
  late String _currentTitle;
  late bool _isDarkMode;
  Set<String> shownNotificationIds = Set<String>();
  bool _hasCheckedNewUsers = false;
  bool _hasCheckedNewCashInLogs = false;
  bool _hasCheckedNewLogs = false;
  late Timer _notificationTimer;
  final List<Widget> _bottomNavPages = [
    HomePage(),
    AlertsPageAdmin(),
    HistoryPageAdmin(),
    MenuAdminPage(),
  ];

  final Map<int, String> _tabTitles = {
    0: 'Admin Dashboard',
    1: 'Admin Alerts',
    2: 'Admin History',
    3: 'Admin Menu',
  };

  Future<Set<String>> loadShownNotificationIds({String key = 'shownNotificationIds'}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> storedIds = prefs.getStringList(key) ?? [];
    return storedIds.toSet();
  }

  Future<void> saveShownNotificationIds(Set<String> shownNotificationIds, {String key = 'shownNotificationIds'}) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(key, shownNotificationIds.toList());
  }

  @override
  void initState() {
    super.initState();
    _isDarkMode = false;
    if (!_hasCheckedNewUsers) {
      _checkNewUsers();
      _hasCheckedNewUsers = true;
    }

    if (!_hasCheckedNewCashInLogs) {
      _checkNewCashInLogs();
      _hasCheckedNewCashInLogs = true;
    }

    if (!_hasCheckedNewLogs) {
      _checkNewLogs();
      _hasCheckedNewLogs = true;
    }
    _selectedBottomNavIndex = widget.selectedIndex;
    _currentTitle = _tabTitles[_selectedBottomNavIndex] ?? 'Admin Dashboard';
    _initializeNotifications();
    _startNotificationStatusChecker();
  }

  void _startNotificationStatusChecker() {
    _notificationTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _initializeNotifications();
      print("every 1 minute");
    });
  }

  @override
  void dispose() {
    _notificationTimer.cancel();
    super.dispose();
  }

  Future<void> _checkNewUsers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in, skipping log check.");
      return;
    }

    Set<String> shownNotificationIds = await loadShownNotificationIds(key: 'shownNotificationIds_users');

    FirebaseFirestore.instance
        .collection('users')
        .where('seen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          String firstName = doc['firstName'] ?? '';
          String lastName = doc['lastName'] ?? '';
          String userName = '$firstName $lastName';
          String email = doc['email'] ?? '';
          Timestamp registrationTime = doc['registerTime'];

          String formattedRegistrationTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(registrationTime.toDate());

          String logId = doc.id;

          if (shownNotificationIds.contains(logId)) {
            print("Notification already shown for user with logId: $logId. Skipping.");
            continue;
          }

          int notificationId = logId.hashCode;

          _showNewUserNotification(userName, email, formattedRegistrationTime, notificationId);

          shownNotificationIds.add(logId);
          print("Added user logId $logId to shownNotificationIds: $shownNotificationIds");

          await saveShownNotificationIds(shownNotificationIds, key: 'shownNotificationIds_users');
        }
      }
    });
  }

  Future<void> _showNewUserNotification(
      String userName, String email, String formattedRegistrationTime, int notificationId) async {

    if (NotificationManager().shownNotificationIds.contains(notificationId)) {
      debugPrint('Notification already shown for this ID: $notificationId');
      return;
    }

    debugPrint('Showing notification for user: $userName with ID: $notificationId');

    String notificationMessage =
        '$userName has registered and is awaiting approval.\n\nAdditional Information:\n- Email: $email\n- Registration Time: $formattedRegistrationTime';

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_user_channel',
      'New User Notifications',
      channelDescription: 'Notifications when a new user registers',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      styleInformation: BigTextStyleInformation(
        notificationMessage,
        htmlFormatContent: true,
        htmlFormatTitle: true,
        contentTitle: 'New User Registration',
      ),
    );

    NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'New User Registered',
      '$userName has registered and is awaiting approval',
      notificationDetails,
      payload: 'new_user',
    );
    debugPrint('Notification shown with payload: new_user');

    NotificationManager().shownNotificationIds.add(notificationId);

    await NotificationManager().saveShownNotificationIds();
  }

  Future<void> _showNewCashInLogNotification(String message, {required String logId}) async {
    int notificationId = logId.hashCode;

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cash_in_logs_channel',
      'Cash-In Logs Notifications',
      channelDescription: 'Notifications for new unapproved cash-in logs',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      styleInformation: BigTextStyleInformation(
        message,
        htmlFormatContent: true,
        htmlFormatTitle: true,
        contentTitle: 'New Cash-In Log',
      ),
    );

    NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'New Cash-In Log',
      message,
      notificationDetails,
      payload: 'new_cash_in',
    );
    NotificationManager().shownNotificationIds.add(notificationId);

    await NotificationManager().saveShownNotificationIds();
  }

  Future<void> _checkNewCashInLogs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in, skipping log check.");
      return;
    }

    Set<String> shownNotificationIds = await loadShownNotificationIds(key: 'shownNotificationIds_cashinlogs');

    FirebaseFirestore.instance
        .collection('cashinlogs')
        .where('seen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          String logId = doc.id;

          if (shownNotificationIds.contains(logId)) {
            print("Notification already shown for logId: $logId. Skipping.");
            continue;
          }

          String adminName = doc['adminName'] ?? 'Unknown Admin';
          int amount = (doc['amount']?.toDouble() ?? 0.0).toInt();
          Timestamp? scannedTime = doc['scannedTime'] as Timestamp?;
          String userName = doc['userName'] ?? 'Unknown User';

          String formattedTime = scannedTime != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(scannedTime.toDate())
              : 'Unknown Time';

          String notificationMessage =
              'New cash-in log for $userName by $adminName. \n\nAdditional information:\n- Admin: $adminName\n- User: $userName\n- Amount: ₱${amount.toStringAsFixed(2)}\n- Time: $formattedTime';

          _showNewCashInLogNotification(notificationMessage, logId: logId);

          shownNotificationIds.add(logId);

          await saveShownNotificationIds(shownNotificationIds, key: 'shownNotificationIds_cashinlogs');
        }
      }
    });
  }

  Future<void> _initializeNotifications() async {
    if (_hasCheckedNewUsers && _hasCheckedNewCashInLogs && _hasCheckedNewLogs) {
      print("Notifications already initialized. Skipping.");
      return;
    }

    for (String logId in shownNotificationIds) {
      if (shownNotificationIds.contains(logId)) {
        print("Notification already shown for logId: $logId. Skipping initialization.");
        return;
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('drawable/app_icon');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _hasCheckedNewUsers = true;
    _hasCheckedNewCashInLogs = true;
    _hasCheckedNewLogs = true;

    print("Notifications initialized successfully.");
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    debugPrint('Notification tapped with payload: ${response.payload}');

    final Map<String, int> payloadActions = {
      'new_login': 1,
      'new_logout': 1,
      'new_cash_in': 1,
      'new_user': 1,
    };

    int targetIndex = payloadActions[response.payload] ?? 0;

    debugPrint('Navigating to Admin Home with selectedIndex: $targetIndex');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MyAdminHomePage(
          title: 'Admin Dashboard',
          selectedIndex: targetIndex,
        ),
      ),
    );
  }

  Future<void> _checkNewLogs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in, skipping log check.");
      return;
    }

    Set<String> shownNotificationIds = await loadShownNotificationIds(key: 'shownNotificationIds_logs');

    FirebaseFirestore.instance
        .collection('loghistory')
        .where('seen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          String logId = doc.id;

          if (shownNotificationIds.contains(logId)) {
            print("Notification already shown for logId: $logId. Skipping.");
            continue;
          }

          String firstName = doc['firstName'] ?? 'Unknown';
          String lastName = doc['lastName'] ?? 'User';
          String userName = '$firstName $lastName';
          Timestamp? scannedTime = doc['scannedTime'] as Timestamp?;
          String logType = doc['type'] ?? 'Unknown';

          String formattedTime = scannedTime != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(scannedTime.toDate())
              : 'Unknown Time';

          String notificationMessage = '';
          if (logType == 'login') {
            notificationMessage =
            'New login log for $userName. \n\nDetails:\n- User: $userName\n- Time: $formattedTime';
          } else if (logType == 'logout') {
            notificationMessage =
            'New logout log for $userName. \n\nDetails:\n- User: $userName\n- Time: $formattedTime';
          }

          _showNewLogNotification(notificationMessage, logId: logId, logType: logType);

          shownNotificationIds.add(logId);

          await saveShownNotificationIds(shownNotificationIds, key: 'shownNotificationIds_logs');
        }
      }
    });
  }

  Future<void> _showNewLogNotification(String message, {required String logId, required String logType}) async {
    int notificationId = logId.hashCode;

    String payload = '';
    if (logType == 'login') {
      payload = 'new_login';
    } else if (logType == 'logout') {
      payload = 'new_logout';
    } else {
      payload = 'new_log';
    }

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'logs_channel',
      'Logs Notifications',
      channelDescription: 'Notifications for new unapproved logs',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      styleInformation: BigTextStyleInformation(
        message,
        htmlFormatContent: true,
        htmlFormatTitle: true,
        contentTitle: 'New Log',
      ),
    );

    NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'New Log Notification',
      message,
      notificationDetails,
      payload: payload,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    double screenWidth = MediaQuery.of(context).size.width;

    double iconSize = screenWidth * 0.06;
    double textSize = screenWidth * 0.02;
    double bottomAppBarHeight = screenWidth * 0.18;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.black : Colors.green.shade200,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                isDarkMode
                    ? 'assets/images/FitTrack_Icon_Dark.png'
                    : 'assets/images/FitTrack_Icon.png',
                width: 40,
                height: 40,
              ),
              Text(
                _currentTitle,
                style: TextStyle(
                  color: isDarkMode ? Colors.green : Colors.black,
                ),
              ),
            ],
          ),
        ),
        body: _bottomNavPages[_selectedBottomNavIndex],
        bottomNavigationBar: BottomAppBar(
          height: bottomAppBarHeight,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          child: Container(
            height: bottomAppBarHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _onBottomNavTapped(0),
                      child: Icon(
                        Icons.table_view,
                        size: iconSize,
                        color: _selectedBottomNavIndex == 0 ? Colors.green : Colors.grey,
                      ),
                    ),
                    Text(
                      'Dashboard',
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
          height: screenWidth * 0.2,
          width: screenWidth * 0.2,
          child: RawMaterialButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScanPage()),
              );
            },
            shape: const CircleBorder(),
            fillColor: Colors.white,
            child: Icon(Icons.qr_code_scanner, size: screenWidth * 0.12, color: Colors.green),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
      _currentTitle = _tabTitles[index] ?? 'Admin Dashboard';
    });
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<int> dailyCounts = List.filled(7, 0);
  List<int> monthlyCounts = List.filled(12, 0);
  Map<int, int> monthlyIncome = {};
  int activeUsersCount = 0;
  int bannedUsersCount = 0;
  int totalUsersCount = 0;
  int totalIncome = 0;
  User? _user;
  DocumentSnapshot? _userData;

  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser;
    super.initState();
    _fetchUserData();
    _fetchAllData();
    fetchLoginCounts();
    fetchTotalIncome();
    fetchMonthlyIncome();
    fetchBannedUsersCount();
    fetchActiveUsersCount();
    fetchUserCounts();
    getDailyCounts().then((counts) {
      setState(() {
        dailyCounts = counts;
      });
    }).catchError((e) {
      print("Error fetching data: $e");
    });
  }

  List<DocumentSnapshot> filteredDocs = [];
  bool _isLoading = true;

  Future<void> _fetchUserData() async {
    try {
      final userId = _user?.uid;
      if (userId != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        setState(() {
          _userData = snapshot;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _fetchUserData(),
        fetchBannedUsersCount(),
        fetchActiveUsersCount(),
        fetchUserCounts(),
        getDailyCounts().then((counts) {
          setState(() {
            dailyCounts = counts;
          });
        }).catchError((e) {
          print("Error fetching daily counts: $e");
        }),
      ]);
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetchAllData();
  }

  String formatDateTime(DateTime dateTime) {
    String year = dateTime.year.toString();
    String month = dateTime.month.toString().padLeft(2, '0');
    String day = dateTime.day.toString().padLeft(2, '0');
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String second = dateTime.second.toString().padLeft(2, '0');

    return '$year-$month-$day-$hour-$minute-$second';
  }

  Future<void> fetchActiveUsersCount() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userStatus', isEqualTo: 'Active')
          .get();

      print("Fetched ${snapshot.docs.length} active users.");

      setState(() {
        activeUsersCount = snapshot.docs.length;
      });
    } catch (e) {
      print("Error fetching active users count: $e");
    }
  }

  Future<void> fetchUserCounts() async {
    try {
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      print("Fetched ${usersSnapshot.docs.length} total users.");

      setState(() {
        totalUsersCount = usersSnapshot.docs.length;
      });
    } catch (e) {
      print("Error fetching total users count: $e");
    }
  }

  Future<void> fetchBannedUsersCount() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userStatus', isEqualTo: 'Banned')
          .get();

      print("Fetched ${snapshot.docs.length} banned users.");

      setState(() {
        bannedUsersCount = snapshot.docs.length;
      });
    } catch (e) {
      print("Error fetching banned users count: $e");
    }
  }

  Future<void> fetchTotalIncome() async {
    totalIncome = 0;

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(
        'cashinlogs').get();

    for (var doc in snapshot.docs) {
      print('Document ID: ${doc.id}');
      print('Amount Field: ${doc['amount']}');

      var amount = doc['amount'];
      if (amount is int) {
        totalIncome += amount;
      } else if (amount is double) {
        totalIncome += amount.toInt();
      } else {
        print("No valid amount field or wrong type in document ${doc.id}");
      }
    }

    setState(() {});
  }

  Future<void> fetchMonthlyIncome() async {
    Map<int, int> incomeByMonth = {};

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(
        'cashinlogs').get();

    for (var doc in snapshot.docs) {
      DateTime scannedDate = (doc['scannedTime'] as Timestamp).toDate();
      int month = scannedDate.month;
      int amount = doc['amount'] ?? 0;

      if (incomeByMonth.containsKey(month)) {
        incomeByMonth[month] = incomeByMonth[month]! + amount;
      } else {
        incomeByMonth[month] = amount;
      }
    }

    totalIncome = incomeByMonth.isNotEmpty
        ? incomeByMonth.values.reduce((a, b) => a + b)
        : 0;

    setState(() {
      monthlyIncome = incomeByMonth;
    });
  }


  Future<void> fetchLoginCounts() async {
    final now = DateTime.now().toUtc();
    final startOfMonth = DateTime.utc(now.year, now.month, 1);
    final endOfMonth = DateTime.utc(now.year, now.month + 1, 1).subtract(
        Duration(seconds: 1));

    print("Start of month: $startOfMonth");
    print("End of month: $endOfMonth");

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(
        'loghistory').get();

    print("Number of documents fetched: ${snapshot.docs.length}");

    for (var doc in snapshot.docs) {
      if (doc['type'] == 'login') {
        if (doc['scannedTime'] is Timestamp) {
          DateTime loginTime = (doc['scannedTime'] as Timestamp).toDate();

          print("Login Time: $loginTime");

          int loginMonth = loginTime.month;

          print("Login Month: $loginMonth");

          switch (loginMonth) {
            case 1:
              monthlyCounts[0]++;
              break;
            case 2:
              monthlyCounts[1]++;
              break;
            case 3:
              monthlyCounts[2]++;
              break;
            case 4:
              monthlyCounts[3]++;
              break;
            case 5:
              monthlyCounts[4]++;
              break;
            case 6:
              monthlyCounts[5]++;
              break;
            case 7:
              monthlyCounts[6]++;
              break;
            case 8:
              monthlyCounts[7]++;
              break;
            case 9:
              monthlyCounts[8]++;
              break;
            case 10:
              monthlyCounts[9]++;
              break;
            case 11:
              monthlyCounts[10]++;
              break;
            case 12:
              monthlyCounts[11]++;
              break;
            default:
              print("Invalid month: $loginMonth");
              break;
          }

          print("Updated monthlyCounts: $monthlyCounts");
        } else {
          print("Invalid 'scannedTime' field: ${doc['scannedTime']}");
        }
      } else {
        print("Skipping document with type: ${doc['type']}");
      }
    }

    print("Final Monthly login counts: $monthlyCounts");
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider
        .of<ThemeProvider>(context)
        .isDarkMode;
    return Scaffold(
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
          Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      _buildUserProfileSection(),
                      SizedBox(height: 10),
                      _buildGraphsSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider
        .of<ThemeProvider>(context)
        .isDarkMode;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? Colors.white
            : Colors.green.shade800.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode
              ? Colors.black87
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseAuth.instance.currentUser != null
                  ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots()
                  : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Text('No user data found.');
                }

                Map<String, dynamic>? _userData = snapshot.data!.data() as Map<
                    String,
                    dynamic>?;
                int profileIconIndex = _userData != null &&
                    _userData['profileIconIndex'] != null
                    ? (_userData['profileIconIndex'] as int) + 1
                    : 1;

                double devicePixelRatio = MediaQuery
                    .of(context)
                    .devicePixelRatio;
                double screenWidth = MediaQuery
                    .of(context)
                    .size
                    .width;
                double avatarRadius;

                if (screenWidth <= 320 || devicePixelRatio < 2.0) {
                  avatarRadius = 30.0;
                } else if (screenWidth <= 480 || devicePixelRatio < 3.0) {
                  avatarRadius = 40.0;
                } else {
                  avatarRadius = 50.0;
                }

                return CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _userData != null &&
                      _userData['profileImage'] != null &&
                      _userData['profileImage'].isNotEmpty
                      ? NetworkImage(_userData['profileImage'])
                      : AssetImage(
                      'assets/images/Icon$profileIconIndex.png') as ImageProvider,
                  child: null,
                );
              },
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      double devicePixelRatio = MediaQuery
                          .of(context)
                          .devicePixelRatio;
                      double screenWidth = MediaQuery
                          .of(context)
                          .size
                          .width;
                      double largeFontSize = (screenWidth <= 320 ||
                          devicePixelRatio < 2.0) ? 15.0 : 20.0;
                      double mediumFontSize = (screenWidth <= 320 ||
                          devicePixelRatio < 2.0) ? 10.0 : 15.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_userData?.get('firstName') ??
                                'First Name'} ${_userData?.get('lastName') ??
                                'Last Name'}",
                            style: TextStyle(fontSize: largeFontSize,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Student ID: ${_userData?.get('userID') ??
                                'Not available'}",
                            style: TextStyle(fontSize: mediumFontSize),
                          ),
                          Text(
                            "User Type: ${_userData?.get('userType') ??
                                'Not available'}",
                            style: TextStyle(fontSize: mediumFontSize),
                          ),
                          Text(
                            "Wallet: ₱ ${_userData?.get('wallet') ??
                                'Not available'}",
                            style: TextStyle(fontSize: mediumFontSize,
                                fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Text(
                                "Status: ",
                                style: TextStyle(
                                  fontSize: mediumFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors
                                      .black,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  _userData?.get('loggedStatus') == false
                                      ? 'Outside'
                                      : 'Inside',
                                  style: TextStyle(
                                    fontSize: mediumFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: _userData?.get('loggedStatus') ==
                                        false ? Colors.red : Colors.green,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildGraphsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return Column(
      children: [
        GestureDetector(
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CountPerDayPage()),
              ),
          child: _buildGraphContainer(
            title: 'CUSTOMER COUNT PER DAY',
            painter: DayHeatmapPainter(
                isDarkMode: isDarkMode, dailyCounts: dailyCounts),
          ),
        ),
        GestureDetector(
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CountPerMonthPage()),
              ),
          child: _buildGraphContainer(
            title: 'CUSTOMER COUNT PER MONTH',
            painter: MonthGraphPainter(
                isDarkMode: isDarkMode, monthlyCounts: monthlyCounts),
          ),
        ),
        GestureDetector(
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => IncomeAdminPage()),
              ),
          child: _buildGraphContainer(
            title: 'Monthly Income',
            painter: IncomeBarPainter(
                isDarkMode: isDarkMode, totalIncome, monthlyIncome),
          ),
        ),
        GestureDetector(
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsersAdminPage()),
              ),
          child: _buildGraphContainer(
            title: 'Users Chart',
            painter: ActiveUsersPainter(
              activeUsersCount,
              bannedUsersCount,
              totalUsersCount,
            ),
            legend: _buildLegend(),
          ),
        ),
      ],
    );
  }

  Widget _buildGraphContainer({
    required String title,
    required CustomPainter painter,
    Widget? legend,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white : Colors.green.shade700,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black87 : Colors.white,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            CustomPaint(
              size: Size(MediaQuery
                  .of(context)
                  .size
                  .width, 80),
              painter: painter,
            ),
            if (legend != null) ...[
              const SizedBox(height: 10),
              legend,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(color: Colors.yellow, label: "On Approval"),
        _buildLegendItem(color: Colors.green, label: "Active"),
        _buildLegendItem(color: Colors.red, label: "Banned"),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}