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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedBottomNavIndex = 0;
  int _drawerIndex = -1;
  String _currentTitle;
  late bool _isDarkMode;

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  _MyHomePageState() : _currentTitle = 'Home';

  @override
  void initState() {
    super.initState();
    _isDarkMode = false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _bottomNavPages = [
      HomePage(),
      AlertsPage(),
      HistoryPage(),
      MenuPage(),
    ];

    final List<Widget> _drawerPages = [
      HomePage(),
      ScanPage(),
      CashInPage(),
      ProfilePage(),
      HistoryPage(),
      AlertsPage(),
      SettingsPage(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade200,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/FitTrack_Icon.png',
              width: 40,
              height: 40,
            ),
            SizedBox(width: 8),
            Text(_currentTitle),
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
              SizedBox(width: 40), // Space for FAB
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
          child: const Icon(Icons.qr_code_scanner, size: 50, color: Colors.green),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
      _drawerIndex = -1;
      _updateTitleBasedOnIndex(index);
    });
  }

  void _updateTitleBasedOnIndex(int index) {
    switch (index) {
      case 0:
        _currentTitle = 'Home';
        break;
      case 1:
        _currentTitle = 'Alerts';
        break;
      case 2:
        _currentTitle = 'History';
        break;
      case 3:
        _currentTitle = 'Menu';
        break;
      default:
        _currentTitle = 'FitTrack';
        break;
    }
  }

  Color _getHomeIconColor() {
    if (_selectedBottomNavIndex == 0 && _drawerIndex == 0) {
      return Colors.green;
    } else if (_drawerIndex == 0) {
      return Colors.green;
    } else {
      return Colors.black54;
    }
  }
}



class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user;
  DocumentSnapshot? _userData;

  // Flag to track whether more images should be shown
  bool _showMoreImages = false;

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
              image: AssetImage('assets/images/bg.png'),
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
                // Existing container
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
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
                            MaterialPageRoute(
                                builder: (context) => ProfilePage()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
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
                                    var _userData = snapshot.data;

                                    return CircleAvatar(
                                      radius: 40,
                                      backgroundImage: _userData != null &&
                                          _userData!.data() != null
                                          ? AssetImage(
                                        'assets/images/Icon${(_userData!.get('profileIconIndex') ?? 1) + 1}.png',
                                      )
                                          : AssetImage('assets/images/Icon1.png'),
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
                                      style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold),
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
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Become a Member",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      // Grid for showing images
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          _buildImageContainer('assets/images/image1.png'),
                          _buildImageContainer('assets/images/image2.png'),
                          _buildImageContainer('assets/images/image3.png'),
                          _buildImageContainer('assets/images/image4.png'),
                          if (_showMoreImages) ...[
                            _buildImageContainer('assets/images/image5.png'),
                            _buildImageContainer('assets/images/image6.png'),
                          ],
                        ],
                      ),
                      SizedBox(height: 10),
                      // Button to show more images
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showMoreImages = !_showMoreImages;
                          });
                        },
                        child: Text(
                          _showMoreImages ? "Show Less" : "Show More",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
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


