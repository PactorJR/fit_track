import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scan_qr.dart';
import 'about.dart';
import 'privacy.dart';
import 'helpsupport.dart';
import 'preferences.dart';
import 'alerts.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
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
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const SettingsPage({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  Future<void> _proceedToSignOut() async {
    try {
      // Sign out the user
      await _auth.signOut();

      // Set dark mode to false (light mode) when the user logs out
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.toggleTheme(false); // Set to light mode

      // Notify the Alerts page (if it's open) to cancel notifications
      alertsPageKey.currentState?.cancelNotificationsOnLogout();

      // Redirect to the LoginPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
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

  final GlobalKey<AlertsPageState> alertsPageKey = GlobalKey<AlertsPageState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            // Switch between background images based on the dark mode
            image: AssetImage(themeProvider.isDarkMode
                ? 'assets/images/dark_bg.png'  // Dark mode background
                : 'assets/images/bg.png'),     // Light mode background
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.green.shade800,
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

                      // Menu items with boxShadow
                      buildMenuItem(
                        title: 'App Theme',
                        icon: Icons.brightness_4,
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (bool value) {
                            themeProvider.toggleTheme(value); // Use provider to update theme globally
                          },
                          activeColor: Colors.black87, // Color of the thumb when the switch is ON
                          activeTrackColor: Colors.grey.shade100, // Color of the track when the switch is ON
                          inactiveThumbColor: Colors.green.shade800, // Color of the thumb when the switch is OFF
                          inactiveTrackColor: Colors.white, // Color of the track when the switch is OFF
                        ),
                        onTap: () {}, // Add an empty onTap if no specific action is required
                      ),

                      buildMenuItem(
                        title: 'Preferences',
                        icon: Icons.settings,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PreferencesPage()),
                          );
                        },
                      ),

                      buildMenuItem(
                        title: 'Help and Support',
                        icon: Icons.help,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HelpSupportPage()),
                          );
                        },
                      ),

                      buildMenuItem(
                        title: 'Privacy & Security',
                        icon: Icons.lock,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PrivacyPage()),
                          );
                        },
                      ),

                      buildMenuItem(
                        title: 'About',
                        icon: Icons.info,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AboutPage()),
                          );
                        },
                      ),

                      buildMenuItem(
                        title: 'Log-Out',
                        icon: Icons.logout,
                        onTap: () async {
                          await _signOut();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => AlertsPage(alertsPageKey: alertsPageKey),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 60, // Adjust this value to move the button down
              left: 16, // Horizontal position
              child: FloatingActionButton(
                mini: true, // Smaller back button
                backgroundColor: isDarkMode ? Colors.grey : Colors.green,
                onPressed: () {
                  Navigator.of(context)
                      .pop(); // Navigate back to the previous screen
                },
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildMenuItem({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) {},
      child: Material(
        color: Colors.transparent,  // Ensures background is transparent
        elevation: 0,  // Shadow effect when pressed
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        child: InkWell(
          onTap: () async {
            // First, animate, then navigate
            await Future.delayed(const Duration(milliseconds: 100));  // Delay to allow animation
            onTap();  // Navigate after animation
          },
          onTapDown: (_) {}, // Optional: can add other effects if needed
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.transparent, // Ensures no background color when not pressed
              borderRadius: BorderRadius.circular(100),
            ),
            child: ListTile(
              leading: Icon(icon, color: Colors.white),
              title: Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: trailing ?? const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ),
          ),
        ),
      ),
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

