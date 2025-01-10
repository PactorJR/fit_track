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
    docId: null, // Default to null unless provided
  ));
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class MyApp extends StatelessWidget {
  final int selectedIndex;
  final String? docId; // Nullable docId parameter

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
        docId: docId, // Pass docId to MyAdminHomePage
      ),
    );
  }
}




class MyAdminHomePage extends StatefulWidget {
  const MyAdminHomePage({
    super.key,
    required this.title,
    this.selectedIndex = 0, // Default to the first tab
    this.docId, // Optional transferable data
  });

  final String? docId; // Nullable docId for optional data transfer
  final String title;
  final int selectedIndex;

  @override
  State<MyAdminHomePage> createState() => _MyHomePageState();
}

class NotificationManager {
  // Private constructor and static instance
  static final NotificationManager _instance = NotificationManager._privateConstructor();

  // Public factory constructor to access the singleton instance
  factory NotificationManager() {
    return _instance;
  }

  // Private named constructor
  NotificationManager._privateConstructor();

  // Track the shown notification IDs
  Set<int> shownNotificationIds = Set();

  // Method to load notification IDs from storage
  Future<void> loadShownNotificationIds() async {
    String? storedIds = await storage.read(key: 'shownNotificationIds');
    if (storedIds != null) {
      shownNotificationIds = Set<int>.from(storedIds.split(',').map((id) => int.parse(id)));
    }
  }

  // Method to save notification IDs to storage
  Future<void> saveShownNotificationIds() async {
    await storage.write(key: 'shownNotificationIds', value: shownNotificationIds.join(','));
  }
}

class _MyHomePageState extends State<MyAdminHomePage> {

  late int _selectedBottomNavIndex;
  late String _currentTitle;
  late bool _isDarkMode;
  Set<String> shownNotificationIds = Set<String>();
  bool _isRemembered = false; // To track if the user is remembered
  bool _hasCheckedNewUsers = false;
  bool _hasCheckedNewCashInLogs = false;
  bool _hasCheckedNewLogs = false;

  // List of pages for the BottomNavigationBar
  final List<Widget> _bottomNavPages = [
    HomePage(),
    AlertsPageAdmin(),
    HistoryPageAdmin(),
    MenuAdminPage(),
  ];

  // Map of titles for each tab index
  final Map<int, String> _tabTitles = {
    0: 'Admin Dashboard',
    1: 'Admin Alerts',
    2: 'Admin History',
    3: 'Admin Menu',
  };

  // Load the shownNotificationIds set from SharedPreferences for different keys
  Future<Set<String>> loadShownNotificationIds({String key = 'shownNotificationIds'}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> storedIds = prefs.getStringList(key) ?? [];
    return storedIds.toSet();
  }

// Save the shownNotificationIds set to SharedPreferences for different keys
  Future<void> saveShownNotificationIds(Set<String> shownNotificationIds, {String key = 'shownNotificationIds'}) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(key, shownNotificationIds.toList());
  }



  @override
  void initState() {
    super.initState();
    _isDarkMode = false;

    // Initialize the current index and title based on the passed parameters
    _selectedBottomNavIndex = widget.selectedIndex;
    _currentTitle = _tabTitles[_selectedBottomNavIndex] ?? 'Admin Dashboard';
    _checkRememberMe(); // Check if the user is remembered
    _initializeNotifications();
  }

  Future<void> _checkNewUsers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in, skipping log check.");
      return; // Exit if no user is logged in
    }

    if (!_isRemembered) return; // Exit if the user is not remembered

    // Load the set of shown notification IDs for users
    Set<String> shownNotificationIds = await loadShownNotificationIds(key: 'shownNotificationIds_users');  // Use unique key for users

    FirebaseFirestore.instance
        .collection('users')
        .where('seen', isEqualTo: false) // Only listen for new users that are unapproved
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          String firstName = doc['firstName'] ?? '';
          String lastName = doc['lastName'] ?? '';
          String userName = '$firstName $lastName';
          String email = doc['email'] ?? '';
          Timestamp registrationTime = doc['registerTime']; // Assuming this exists

          // Format the registration time
          String formattedRegistrationTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(registrationTime.toDate());

          String logId = doc.id;  // Use the document ID as the logId

          // Check if this user has already been notified
          if (shownNotificationIds.contains(logId)) {
            print("Notification already shown for user with logId: $logId. Skipping.");
            continue; // Skip this user if already notified
          }

          // Generate a unique notificationId based on doc.id
          int notificationId = logId.hashCode;

          // Show the notification with additional information and unique ID
          _showNewUserNotification(userName, email, formattedRegistrationTime, notificationId);

          // Add the logId to the set of shown notifications to avoid duplicates
          shownNotificationIds.add(logId);
          print("Added user logId $logId to shownNotificationIds: $shownNotificationIds");

          // Save the updated set of shown notification IDs to SharedPreferences
          await saveShownNotificationIds(shownNotificationIds, key: 'shownNotificationIds_users');  // Use unique key for users
        }
      }
    });
  }



  // Method to show notification with user details
  Future<void> _showNewUserNotification(
      String userName, String email, String formattedRegistrationTime, int notificationId) async {

    // Check if this notificationId has already been shown using the singleton
    if (NotificationManager().shownNotificationIds.contains(notificationId)) {
      debugPrint('Notification already shown for this ID: $notificationId');
      return; // Don't show the notification if we've already shown it
    }

    debugPrint('Showing notification for user: $userName with ID: $notificationId');

    // Create the expanded notification style with additional information
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
      notificationId, // Use unique notification ID
      'New User Registered',
      '$userName has registered and is awaiting approval',
      notificationDetails,
      payload: 'new_user', // Pass payload for navigation
    );
    debugPrint('Notification shown with payload: new_user');

    // Add this notificationId to the set to track it
    NotificationManager().shownNotificationIds.add(notificationId);

    // Save the updated list of shown notification IDs using the singleton
    await NotificationManager().saveShownNotificationIds();
  }

  Future<void> _showNewCashInLogNotification(String message, {required String logId}) async {
    int notificationId = logId.hashCode; // Generate a unique ID based on logId

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
    // Save this notificationId to the singleton
    NotificationManager().shownNotificationIds.add(notificationId);

    // Save the updated list of shown notification IDs using the singleton
    await NotificationManager().saveShownNotificationIds();
  }

  // Method to check new cash-in logs and show notifications
  Future<void> _checkNewCashInLogs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in, skipping log check.");
      return; // Exit if no user is logged in
    }
    if (!_isRemembered) return; // Exit if the user is not remembered

    // Load the set of shown notification IDs for cash-in logs
    Set<String> shownNotificationIds = await loadShownNotificationIds(key: 'shownNotificationIds_cashinlogs');

    FirebaseFirestore.instance
        .collection('cashinlogs')
        .where('seen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          String logId = doc.id; // Get the unique ID of the log

          // Check if this log has already been notified
          if (shownNotificationIds.contains(logId)) {
            print("Notification already shown for logId: $logId. Skipping.");
            continue; // Skip if this log has already been notified
          }

          String adminName = doc['adminName'] ?? '';
          int amount = (doc['amount']?.toDouble() ?? 0.0).toInt();  // Convert to int
          Timestamp scannedTime = doc['scannedTime'];
          String userName = doc['userName'] ?? '';

          // Format the scanned time
          String formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(scannedTime.toDate());

          // Create the notification message
          String notificationMessage =
              'New cash-in log for $userName by $adminName. \n\nAdditional information:\n- Admin: $adminName\n- User: $userName\n- Amount: ₱${amount.toStringAsFixed(2)}\n- Time: $formattedTime';

          // Show the notification
          _showNewCashInLogNotification(notificationMessage, logId: logId);

          // Add this logId to the set of shown notifications to avoid duplicates
          shownNotificationIds.add(logId);

          // Save the updated set to SharedPreferences after each addition
          await saveShownNotificationIds(shownNotificationIds, key: 'shownNotificationIds_cashinlogs');
        }
      }
    });
  }



  // Check if the user has enabled "Remember Me"
  Future<void> _checkRememberMe() async {
    String? value = await storage.read(key: 'isRemembered');

    if (value == 'true') {
      setState(() {
        _isRemembered = true;
      });

      // Check and trigger notifications only if not already initialized
      if (!_hasCheckedNewUsers) {
        _checkNewUsers();
        _hasCheckedNewUsers = true; // Mark as initialized
      }

      if (!_hasCheckedNewCashInLogs) {
        _checkNewCashInLogs();
        _hasCheckedNewCashInLogs = true; // Mark as initialized
      }

      if (!_hasCheckedNewLogs) {
        _checkNewLogs();
        _hasCheckedNewLogs = true; // Mark as initialized
      }

      // Call _initializeNotifications only after confirming the user is remembered
      await _initializeNotifications();
    } else {
      debugPrint('User is not remembered. Notifications will not run.');
    }
  }

  Future<void> _initializeNotifications() async {
    // Prevent unnecessary re-initialization
    if (_hasCheckedNewUsers && _hasCheckedNewCashInLogs && _hasCheckedNewLogs) {
      print("Notifications already initialized. Skipping.");
      return;
    }

    // Proceed with initialization only if notifications haven't been initialized
    for (String logId in shownNotificationIds) {
      if (shownNotificationIds.contains(logId)) {
        print("Notification already shown for logId: $logId. Skipping initialization.");
        return; // Skip initialization if any logId is found in the shownNotificationIds
      }
    }

    // If no match was found, proceed with initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('drawable/app_icon');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    // Initialize local notifications
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Mark initialization complete
    _hasCheckedNewUsers = true;
    _hasCheckedNewCashInLogs = true;
    _hasCheckedNewLogs = true;

    print("Notifications initialized successfully.");
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    debugPrint('Notification tapped with payload: ${response.payload}');

    // Define a map for payloads and their corresponding selectedIndex
    final Map<String, int> payloadActions = {
      'new_login': 1,
      'new_logout': 1,
      'new_cash_in': 1,
      'new_user': 1,
    };

    // Get the target index from the map or use 0 if payload is not found
    int targetIndex = payloadActions[response.payload] ?? 0;

    debugPrint('Navigating to Admin Home with selectedIndex: $targetIndex');

    // Navigate to MyAdminHomePage with the selectedIndex
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
      return; // Exit if no user is logged in
    }

    if (!_isRemembered) return;

    // Load the set of shown notification IDs for log history
    Set<String> shownNotificationIds = await loadShownNotificationIds(key: 'shownNotificationIds_logs');

    FirebaseFirestore.instance
        .collection('loghistory')
        .where('seen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          String logId = doc.id; // Use raw doc.id as a String

          // Check if this logId has already been shown (skip it if it's in the set)
          if (shownNotificationIds.contains(logId)) {
            print("Notification already shown for logId: $logId. Skipping.");
            continue; // Skip the rest of the loop if logId has already been notified
          }

          String firstName = doc['firstName'] ?? '';
          String lastName = doc['lastName'] ?? '';
          String userName = '$firstName $lastName';
          Timestamp scannedTime = doc['scannedTime'];
          String logType = doc['type'] ?? '';

          // Format the scanned time
          String formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(scannedTime.toDate());

          // Create the notification message based on the type (login/logout)
          String notificationMessage = '';
          if (logType == 'login') {
            notificationMessage =
            'New login log for $userName. \n\nDetails:\n- User: $userName\n- Time: $formattedTime';
          } else if (logType == 'logout') {
            notificationMessage =
            'New logout log for $userName. \n\nDetails:\n- User: $userName\n- Time: $formattedTime';
          }

          // Show the notification and mark it as shown
          _showNewLogNotification(notificationMessage, logId: logId, logType: logType);

          // Add the logId to the set of shown notifications, ensuring no duplicates
          shownNotificationIds.add(logId);

          // Save the updated set to SharedPreferences
          await saveShownNotificationIds(shownNotificationIds, key: 'shownNotificationIds_logs');
        }
      }
    });
  }

  Future<void> _showNewLogNotification(String message, {required String logId, required String logType}) async {
    int notificationId = logId.hashCode; // Generate a unique ID based on logId

    // Set the payload based on the log type (login or logout)
    String payload = '';
    if (logType == 'login') {
      payload = 'new_login';
    } else if (logType == 'logout') {
      payload = 'new_logout';
    } else {
      payload = 'new_log'; // Default case, if type is unrecognized
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
      payload: payload,  // Pass the dynamic payload
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
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
      body: _bottomNavPages[_selectedBottomNavIndex],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.table_view),
              color: _selectedBottomNavIndex == 0 ? Colors.green : Colors.grey,
              onPressed: () => _onBottomNavTapped(0),
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              color: _selectedBottomNavIndex == 1 ? Colors.green : Colors.grey,
              onPressed: () => _onBottomNavTapped(1),
            ),
            const SizedBox(width: 40), // Space for FAB in the center
            IconButton(
              icon: const Icon(Icons.history),
              color: _selectedBottomNavIndex == 2 ? Colors.green : Colors.grey,
              onPressed: () => _onBottomNavTapped(2),
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              color: _selectedBottomNavIndex == 3 ? Colors.green : Colors.grey,
              onPressed: () => _onBottomNavTapped(3),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        height: 100.0,
        width: 100.0,
        child: RawMaterialButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ScanPage()),
            );
          },
          shape: const CircleBorder(),
          fillColor: Colors.white,
          child: const Icon(Icons.qr_code_scanner, size: 50, color: Colors.green),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
        dailyCounts = counts; // Update the dailyCounts after fetching data
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
            dailyCounts = counts; // Update the dailyCounts after fetching data
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
    await _fetchAllData(); // Refresh all data
  }


  String formatDateTime(DateTime dateTime) {
    String year = dateTime.year.toString();
    String month = dateTime.month.toString().padLeft(
        2, '0'); // Ensure 2-digit month
    String day = dateTime.day.toString().padLeft(2, '0'); // Ensure 2-digit day
    String hour = dateTime.hour.toString().padLeft(
        2, '0'); // Ensure 2-digit hour
    String minute = dateTime.minute.toString().padLeft(
        2, '0'); // Ensure 2-digit minute
    String second = dateTime.second.toString().padLeft(
        2, '0'); // Ensure 2-digit second

    return '$year-$month-$day-$hour-$minute-$second';
  }

  Future<void> fetchActiveUsersCount() async {
    try {
      // Query to fetch documents where 'userStatus' is 'Active'
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userStatus', isEqualTo: 'Active') // Filter by 'Active' status
          .get();

      // Debugging: Print the number of documents fetched
      print("Fetched ${snapshot.docs.length} active users.");

      setState(() {
        activeUsersCount = snapshot.docs.length; // Count active users only
      });
    } catch (e) {
      // Handle errors (e.g., connection issues)
      print("Error fetching active users count: $e");
    }
  }

  Future<void> fetchUserCounts() async {
    try {
      // Fetch all users from the 'users' collection
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      // Debugging: Print the total number of users fetched
      print("Fetched ${usersSnapshot.docs.length} total users.");

      setState(() {
        totalUsersCount = usersSnapshot.docs
            .length; // Total number of users in the collection
      });
    } catch (e) {
      // Handle any errors that occur during the fetch
      print("Error fetching total users count: $e");
    }
  }

  Future<void> fetchBannedUsersCount() async {
    try {
      // Query to fetch documents where 'userStatus' is 'Active'
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userStatus', isEqualTo: 'Banned') // Filter by 'Banned' status
          .get();

      // Debugging: Print the number of documents fetched
      print("Fetched ${snapshot.docs.length} banned users.");

      setState(() {
        bannedUsersCount = snapshot.docs.length; // Count active users only
      });
    } catch (e) {
      // Handle errors (e.g., connection issues)
      print("Error fetching banned users count: $e");
    }
  }

  Future<void> fetchTotalIncome() async {
    // Clear the previous total income before fetching new data
    totalIncome = 0;

    // Fetch all documents from the 'cashinlogs' collection
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(
        'cashinlogs').get();

    // Debugging: Print the document IDs and the amount field to check if it's correctly accessed
    for (var doc in snapshot.docs) {
      print('Document ID: ${doc.id}');
      print('Amount Field: ${doc['amount']}'); // Log the 'amount' field

      // If 'amount' exists and is of type int, add to totalIncome
      var amount = doc['amount'];
      if (amount is int) {
        totalIncome += amount;
      } else if (amount is double) {
        totalIncome += amount.toInt(); // Convert double to int if necessary
      } else {
        print("No valid amount field or wrong type in document ${doc.id}");
      }
    }

    // Trigger UI update
    setState(() {});
  }

  // Fetch data from Firestore and calculate total and monthly income
  Future<void> fetchMonthlyIncome() async {
    Map<int, int> incomeByMonth = {}; // Local map to store income by month

    // Fetch all documents from the 'cashinlogs' collection
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(
        'cashinlogs').get();

    for (var doc in snapshot.docs) {
      DateTime scannedDate = (doc['scannedTime'] as Timestamp).toDate();
      int month = scannedDate.month; // Get the month from the scannedTime
      int amount = doc['amount'] ??
          0; // Get the amount field, default to 0 if null

      // Sum income for each month
      if (incomeByMonth.containsKey(month)) {
        incomeByMonth[month] = incomeByMonth[month]! + amount;
      } else {
        incomeByMonth[month] = amount;
      }
    }

    // Calculate total income (sum of all monthly income)
    totalIncome = incomeByMonth.values.reduce((a, b) => a + b);

    // Update the state with monthly income data
    setState(() {
      monthlyIncome = incomeByMonth;
    });
  }

  Future<void> fetchLoginCounts() async {
    final now = DateTime.now().toUtc(); // Get the current UTC time
    final startOfMonth = DateTime.utc(
        now.year, now.month, 1); // Start of this month
    final endOfMonth = DateTime.utc(now.year, now.month + 1, 1).subtract(
        Duration(seconds: 1)); // End of this month

    // Debug: Print the range you're querying
    print("Start of month: $startOfMonth");
    print("End of month: $endOfMonth");

    // Fetch documents from the loghistory collection
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(
        'loghistory').get();

    // Check if there are any documents in the snapshot
    print("Number of documents fetched: ${snapshot.docs.length}");

    // Iterate over the documents
    for (var doc in snapshot.docs) {
      // Check if the 'type' field is 'login'
      if (doc['type'] == 'login') {
        // Extract the timestamp and convert to DateTime
        if (doc['scannedTime'] is Timestamp) {
          DateTime loginTime = (doc['scannedTime'] as Timestamp)
              .toDate(); // Convert Timestamp to DateTime

          // Debug: Print the login time for each document
          print("Login Time: $loginTime");

          // Extract the month component of the login time
          int loginMonth = loginTime.month;

          // Debug: Print the login month
          print("Login Month: $loginMonth");

          // Use a switch statement to update the monthlyCounts based on loginMonth
          switch (loginMonth) {
            case 1:
              monthlyCounts[0]++; // January
              break;
            case 2:
              monthlyCounts[1]++; // February
              break;
            case 3:
              monthlyCounts[2]++; // March
              break;
            case 4:
              monthlyCounts[3]++; // April
              break;
            case 5:
              monthlyCounts[4]++; // May
              break;
            case 6:
              monthlyCounts[5]++; // June
              break;
            case 7:
              monthlyCounts[6]++; // July
              break;
            case 8:
              monthlyCounts[7]++; // August
              break;
            case 9:
              monthlyCounts[8]++; // September
              break;
            case 10:
              monthlyCounts[9]++; // October
              break;
            case 11:
              monthlyCounts[10]++; // November
              break;
            case 12:
              monthlyCounts[11]++; // December
              break;
            default:
              print("Invalid month: $loginMonth");
              break;
          }

          // Debug: Print the updated monthlyCounts after each login
          print("Updated monthlyCounts: $monthlyCounts");
        } else {
          print("Invalid 'scannedTime' field: ${doc['scannedTime']}");
        }
      } else {
        // If it's not a login, don't count it
        print("Skipping document with type: ${doc['type']}");
      }
    }

    // Debug: Print the final monthly counts
    print("Final Monthly login counts: $monthlyCounts");
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      body: Stack(
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
          Padding(
            padding: const EdgeInsets.only(top: 0.0), // Space below the title
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      // User Profile Section
                      _buildUserProfileSection(),
                      SizedBox(height: 10),
                      // Graphs Section
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
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      padding: const EdgeInsets.all(20),
      // Padding for the outer green container
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? Colors.white  // White background for dark mode
            : Colors.green.shade800.withOpacity(0.8),  // Green background for light mode
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        // Padding for inner white container
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode
              ? Colors.black87 // Black background for dark mode
              : Colors.white, // White background for light mode
          borderRadius: BorderRadius.circular(15), // Rounded corners
        ),
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
                  print('User document data: $_userData');

                  // Retrieve profileIconIndex or use default and add +1
                  int profileIconIndex = _userData != null && _userData['profileIconIndex'] != null
                      ? (_userData['profileIconIndex'] as int) + 1
                      : 1; // Default to 1 if profileIconIndex is null or missing

                  // Debug log for the profileIconIndex
                  print('Updated profileIconIndex (with +1): $profileIconIndex');

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
                    "${_userData?.get('firstName') ?? 'First Name'} ${_userData
                        ?.get('lastName') ?? 'Last Name'}",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Student ID: ${_userData?.get('userID') ??
                        'Not available'}",
                    style: TextStyle(fontSize: 17),
                  ),
                  Text(
                    "User Type: ${_userData?.get('userType') ??
                        'Not available'}",
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
    );
  }

  Widget _buildGraphsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CountPerDayPage()),
          ),
          child: _buildGraphContainer(
            title: 'CUSTOMER COUNT PER DAY',
            painter: DayHeatmapPainter(isDarkMode: isDarkMode, dailyCounts: dailyCounts),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CountPerMonthPage()),
          ),
          child: _buildGraphContainer(
            title: 'CUSTOMER COUNT PER MONTH',
            painter: MonthGraphPainter(isDarkMode: isDarkMode, monthlyCounts: monthlyCounts),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IncomeAdminPage()),
          ),
          child: _buildGraphContainer(
            title: 'Monthly Income',
            painter: IncomeBarPainter(isDarkMode: isDarkMode, totalIncome, monthlyIncome),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
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
            legend: _buildLegend(), // Pass the legend only for the Users Chart
          ),
        ),
      ],
    );
  }


  Widget _buildGraphContainer({
    required String title,
    required CustomPainter painter,
    Widget? legend, // Optional parameter for the legend
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode; // Simplified for readability

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white : Colors.green.shade700,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black, // Text color changes based on theme
              ),
            ),
            const SizedBox(height: 10),
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 80),
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
            borderRadius: BorderRadius.circular(4), // Slightly rounded box
          ),
        ),
        const SizedBox(width: 8), // Spacing between box and label
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}