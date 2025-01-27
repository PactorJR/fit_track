import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scan_qr.dart';
import 'about.dart';
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
  bool _isDarkMode = false;

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
          headlineSmall: TextStyle(color: Colors.white),
        ),
        scaffoldBackgroundColor: Colors.black87,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black87,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      )
          : ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.green.shade100,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          headlineSmall: TextStyle(color: Colors.black),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.black),
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
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user is currently logged in.')),
      );
      return;
    }

    try {
      await _auth.signOut();

      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.toggleTheme(false);

      alertsPageKey.currentState?.cancelNotificationsOnLogout();

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
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user is currently logged in.')),
        );
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final loggedStatus = userDoc.data()?['loggedStatus'];

        if (loggedStatus == true) {
          _showLogoutPrompt();
          return;
        }
      }

      await FirebaseAuth.instance.signOut();
      Provider.of<ThemeProvider>(context, listen: false).toggleTheme(false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Scan QR"),
              onPressed: () {
                Navigator.of(context).pop();
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
            image: AssetImage(themeProvider.isDarkMode
                ? 'assets/images/dark_bg.png'
                : 'assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery
                    .of(context)
                    .size
                    .width < 360 ? 10.0 : 16.0),
                child: Container(
                  padding: EdgeInsets.all(MediaQuery
                      .of(context)
                      .size
                      .width < 360 ? 12.0 : 16.0),
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
                              fontSize: MediaQuery
                                  .of(context)
                                  .size
                                  .width < 360 ? 15 : 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      buildMenuItem(
                        context: context,
                        title: 'App Theme',
                        icon: Icons.brightness_4,
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (bool value) {
                            themeProvider.toggleTheme(value);
                          },
                          activeColor: Colors.black87,
                          activeTrackColor: Colors.grey.shade100,
                          inactiveThumbColor: Colors.green.shade800,
                          inactiveTrackColor: Colors.white,
                        ),
                        onTap: () {},
                      ),
                      buildMenuItem(
                        context: context,
                        title: 'Preferences',
                        icon: Icons.settings,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PreferencesPage()),
                          );
                        },
                      ),
                      buildMenuItem(
                        context: context,
                        title: 'Help and Support',
                        icon: Icons.help,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HelpSupportPage()),
                          );
                        },
                      ),
                      buildMenuItem(
                        context: context,
                        title: 'About',
                        icon: Icons.info,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AboutPage()),
                          );
                        },
                      ),
                      buildMenuItem(
                        context: context,
                        title: 'Log-Out',
                        icon: Icons.logout,
                        onTap: () async {
                          await _signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 16,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: isDarkMode ? Colors.grey : Colors.green,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
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
    required BuildContext context,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    double iconSize = MediaQuery
        .of(context)
        .size
        .width < 360 ? 18 : 24;
    double fontSize = MediaQuery
        .of(context)
        .size
        .width < 360 ? 16 : 17;

    return GestureDetector(
      onTapDown: (_) {},
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 3),
        color: isDarkMode ? Colors.grey.shade700 : Colors.green.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          onTap: () async {
            await Future.delayed(
                const Duration(milliseconds: 100));
            onTap();
          },
          onTapDown: (_) {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: Icon(icon, color: Colors.white, size: iconSize),
              title: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                ),
              ),
              trailing: trailing ??
                  const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

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

