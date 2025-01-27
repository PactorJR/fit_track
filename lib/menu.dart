import 'package:fit_track/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings.dart';
import 'cash_in.dart';
import 'profile.dart';
import 'scan_qr.dart';
import 'login.dart';
import 'member_benefits.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

import 'alerts.dart';

class MenuPage extends StatelessWidget {
  final GlobalKey<AlertsPageState> alertsPageKey = GlobalKey<AlertsPageState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection(
            'users').doc(user.uid).get();
        return snapshot.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }

  Future<void> _proceedToSignOut(BuildContext context) async {

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
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text('No user logged in'));
    }

    final userId = user.uid;
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body: Container(
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
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _fetchUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData) {
                return Center(child: Text('No user data found.'));
              } else {
                var userData = snapshot.data!;

                return ListView(
                  children: [
                    Container(
                      color: isDarkMode
                          ? Colors.black38
                          : Colors.green[700]?.withOpacity(0.9),
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              }
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }
                              if (snapshot.hasData) {
                                Map<String, dynamic>? _userData = snapshot.data!.data() as Map<String, dynamic>?;

                                int profileIconIndex = _userData != null && _userData['profileIconIndex'] != null
                                    ? (_userData['profileIconIndex'] as int) + 1
                                    : 1;

                                return CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: _userData != null && _userData['profileImage'] != null && _userData['profileImage'].isNotEmpty
                                      ? NetworkImage(_userData['profileImage'])
                                      : AssetImage('assets/images/Icon$profileIconIndex.png') as ImageProvider,
                                );
                              }
                              return Text('No user data found.');
                            },
                          ),
                          SizedBox(height: 10),
                          Text(
                            "${userData['firstName'] ?? 'Unknown'} ${userData['lastName'] ?? 'User'}",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "User ID: ${userData['userID'] ?? 'Not available'}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified,
                                color: isDarkMode ? Colors.white : Colors.amberAccent,
                              ),
                              Text(
                                "You are a member!",
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.amberAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MemberBenefitsPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode ? Colors.black38 : Colors.white,
                                  foregroundColor: isDarkMode ? Colors.white : Colors.green,
                                ),
                                child: Text("View Features"),
                              ),
                              SizedBox(width: 10),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildMenuItem(
                      context,
                      icon: Icons.qr_code,
                      label: "Scan QR",
                      page: ScanPage(),
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.attach_money,
                      label: "Cash-In",
                      page: CashInPage(),
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications,
                      label: "Alerts",
                      page: MyHomePage(title: 'History', selectedIndex: 1, docId: null, cameFromScanPage: true),
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.history,
                      label: "History",
                      page: MyHomePage(title: 'History', selectedIndex: 2, docId: null, cameFromScanPage: true),
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.person,
                      label: "Profile",
                      page: ProfilePage(),
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings,
                      label: "Settings",
                      page: SettingsPage(
                        isDarkMode: isDarkMode,
                        onThemeChanged: (bool isDarkMode) {},
                      ),
                      isDarkMode: isDarkMode,
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String label,
    required Widget page,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),

        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          color: isDarkMode ? Colors.grey.shade700 : Colors.green.shade700,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                15),
          ),
          child: InkWell(
            onTap: () async {

              await Future.delayed(const Duration(
                  milliseconds: 100));
              Navigator.push(
                context,
                MaterialPageRoute(builder: (
                    context) => page),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: Colors.transparent,

                borderRadius: BorderRadius.circular(
                    15),
              ),
              child: ListTile(
                leading: Icon(
                  icon,
                  color: isDarkMode ? Colors.white : Colors
                      .white,
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors
                        .white,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: isDarkMode ? Colors.white : Colors
                      .white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

