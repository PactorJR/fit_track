import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings.dart';
import 'users_admin.dart';
import 'profile.dart';
import 'graphs_admin.dart'; // Ensure this file exists and is defined correctly
import 'history.dart';
import 'alerts.dart';
import 'scan_qr.dart';

class MenuAdminPage extends StatelessWidget {
  Future<Map<String, dynamic>?> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        return snapshot.data() as Map<String, dynamic>?; // Ensure this structure matches your Firestore data
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text('No user logged in'));
    }

    final userId = user.uid;
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(  // Fetch user data asynchronously
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
                // User Profile Section
                Container(
                  color: Colors.green[700],
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          if (snapshot.hasData) {
                            var _userData = snapshot.data;
                            return CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              backgroundImage: _userData != null && _userData.data() != null
                                  ? AssetImage(
                                'assets/images/Icon${(_userData!.get('profileIconIndex') ?? 1) + 1}.png',
                              )
                                  : AssetImage('assets/images/Icon1.png'),
                            );
                          }
                          return Text('No user data found.');
                        },
                      ),
                      SizedBox(height: 10),
                      Text(
                        "${userData['firstName'] ?? 'Unknown'} ${userData['lastName'] ?? 'User'}",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        "Student ID: ${userData['userID'] ?? 'Not available'}",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified, color: Colors.amberAccent),
                          Text(
                            "Become a member!",
                            style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to benefits page
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green,
                            ),
                            child: Text("View Benefits"),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              // Handle logout
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green,
                            ),
                            child: Text("Log-out"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Menu Items Section
                _buildMenuItem(context, icon: Icons.qr_code, label: "Scan QR", page: ScanPage()),
                _buildMenuItem(context, icon: Icons.people, label: "Users", page: UsersAdminPage()),
                _buildMenuItem(context, icon: Icons.person, label: "Profile", page: ProfilePage()),
                _buildMenuItem(context, icon: Icons.table_view, label: "Graphs", page: GraphsAdminPage()), // Ensure this is defined
                _buildMenuItem(context, icon: Icons.settings, label: "Settings", page: SettingsPage(
                  isDarkMode: false,
                  onThemeChanged: (bool isDarkMode) {
                    // Handle theme change if needed
                  },
                )),
              ],
            );
          }
        },
      ),
    );
  }

  // Helper method to build each menu item
  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String label, required Widget page}) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[800]),
      title: Text(label),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.green[800]),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}
