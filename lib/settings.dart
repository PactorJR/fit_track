import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scan_qr.dart';
import 'about.dart';
import 'privacy.dart';
import 'helpsupport.dart';
import 'preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false; // Initialize the theme with a default value

  // Toggles the theme between light and dark modes
  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white), // AppBar text
        ),
        scaffoldBackgroundColor: Colors.black87,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black87, // Dark AppBar background
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.white), // AppBar icons
        ),
      )
          : ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.green.shade100,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          headlineSmall: TextStyle(color: Colors.black), // AppBar text
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green, // Light AppBar background
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.black), // AppBar icons
        ),
      ),
      home: SettingsPage(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
      ),
      routes: {
        '/login': (context) => LoginPage(),
      },
    );
  }
}

class SettingsPage extends StatefulWidget {
  final bool isDarkMode; // Accepts the current theme mode
  final Function(bool) onThemeChanged; // Callback to toggle the theme

  const SettingsPage({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode; // Initialize with the passed theme mode
  }

  Future<void> _signOut() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('logintime')
          .where('userID', isEqualTo: user.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot snapshot = querySnapshot.docs.first;
        var data = snapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          print("loggedOut value: ${data['loggedOut']}");

          if (data['loggedOut'] == false) {
            print("loggedOut is false, showing prompt");
            _showLogoutPrompt();
          } else {
            print("loggedOut is true, proceeding to sign out");
            _proceedToSignOut();
          }
        }
      } else {
        print("No document found for this user, proceeding to sign out");
        _proceedToSignOut();
      }
    }
  }

  void _showLogoutPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Scan Required"),
          content: Text("You need to scan the QR code to logout."),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Scan QR"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ScanPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _proceedToSignOut() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black87 : Colors.green.shade100,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey.shade800 : Colors.green.shade800,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Colors.white, size: 30),
                        const SizedBox(width: 10),
                        Text(
                          'SETTINGS',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // App Theme Option
                    buildMenuItem(
                      title: 'App Theme',
                      icon: Icons.brightness_6,
                      trailing: Switch(
                        value: _isDarkMode,
                        onChanged: (bool value) {
                          setState(() {
                            _isDarkMode = value; // Update local state
                            widget.onThemeChanged(value); // Update global state
                          });
                        },
                      ),
                      onTap: () {}, // Add an empty onTap if no specific action is required
                    ),

                    // Preferences Option
                    buildMenuItem(
                      title: 'Preferences',
                      icon: Icons.settings,
                      onTap: () {
                        // Navigate to Preferences page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PreferencesPage()),
                        );
                      },
                    ),

                    // Help and Support Option
                    buildMenuItem(
                      title: 'Help and Support',
                      icon: Icons.help,
                      onTap: () {
                        // Navigate to Help and Support page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HelpSupportPage()),
                        );
                      },
                    ),

                    // Privacy & Security Option
                    buildMenuItem(
                      title: 'Privacy & Security',
                      icon: Icons.lock,
                      onTap: () {
                        // Navigate to Privacy & Security page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PrivacyPage()),
                        );
                      },
                    ),

                    // About Option
                    buildMenuItem(
                      title: 'About',
                      icon: Icons.info,
                      onTap: () {
                        // Navigate to About page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AboutPage()),
                        );
                      },
                    ),

                    // Logout Option
                    buildMenuItem(
                      title: 'Log-Out',
                      icon: Icons.logout,
                      onTap: _signOut, // Call the logout function
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40, // Adjust this value to place the button at the top
            left: 16, // Horizontal position
            child: FloatingActionButton(
              mini: true, // Smaller back button
              backgroundColor: Colors.green,
              onPressed: () {
                Navigator.of(context).pop(); // Navigate back to the previous screen
              },
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Move the buildMenuItem function outside the build method
  Widget buildMenuItem({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Function() onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, color: Colors.white),
      onTap: onTap,
    );
  }
}

// Move the SettingsOption class outside
class SettingsOption extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SettingsOption({Key? key, required this.title, this.trailing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: Colors.white),
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, color: Colors.white),
      ),
    );
  }
}

