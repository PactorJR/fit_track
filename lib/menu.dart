import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings.dart';
import 'cash_in.dart';
import 'profile.dart';
import 'scan_qr.dart';
import 'login.dart';
import 'member_benefits.dart';

class MenuPage extends StatelessWidget {
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

  Future<void> _signOut(BuildContext context) async {
    // Pass context here
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
            _showLogoutPrompt(context); // Pass context here
          } else {
            print("loggedOut is true, proceeding to sign out");
            _proceedToSignOut(context); // Pass context here
          }
        }
      } else {
        print("No document found for this user, proceeding to sign out");
        _proceedToSignOut(context); // Pass context here
      }
    }
  }

  void _showLogoutPrompt(BuildContext context) {
    // Accept context as parameter
    showDialog(
      context: context, // Use the passed context
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

  Future<void> _proceedToSignOut(BuildContext context) async {
    // Accept context as parameter
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

    return WillPopScope(
      onWillPop: () async {
        return false; // Prevents the default back navigation.
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background container with the image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Foreground content
            FutureBuilder<Map<String, dynamic>?>(
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
                        color: Colors.green[700]?.withOpacity(0.9),
                        // Optional overlay for better contrast
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection(
                                  'users').doc(userId).snapshots(),
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
                                    backgroundColor: Colors.white,
                                    backgroundImage: _userData != null &&
                                        _userData.data() != null
                                        ? AssetImage(
                                        'assets/images/Icon${(_userData!.get(
                                            'profileIconIndex') ?? 1) + 1}.png')
                                        : AssetImage('assets/images/Icon1.png'),
                                  );
                                }
                                return Text('No user data found.');
                              },
                            ),
                            SizedBox(height: 10),
                            Text(
                              "${userData['firstName'] ??
                                  'Unknown'} ${userData['lastName'] ?? 'User'}",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "User ID: ${userData['userID'] ??
                                  'Not available'}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified, color: Colors.amberAccent),
                                Text(
                                  "Become a member!",
                                  style: TextStyle(
                                    color: Colors.amberAccent,
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
                                      MaterialPageRoute(builder: (context) =>
                                          MemberBenefitsPage()), // Replace with your actual MemberBenefitsPage widget
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    // Button color
                                    foregroundColor: Colors.green, // Text color
                                  ),
                                  child: Text("View Benefits"),
                                ),
                                SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    _signOut(context); // Pass context here
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    // Button color
                                    foregroundColor: Colors.green, // Text color
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
                      _buildMenuItem(
                        context,
                        icon: Icons.qr_code,
                        label: "Scan QR",
                        page: ScanPage(), // Replace with your ScanPage widget
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.attach_money,
                        label: "Cash-In",
                        page: CashInPage(), // Replace with your CashInPage widget
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.person,
                        label: "Profile",
                        page: ProfilePage(), // Replace with your ProfilePage widget
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.settings,
                        label: "Settings",
                        page: SettingsPage(
                          isDarkMode: false,
                          // You can replace this with a dynamic value if needed
                          onThemeChanged: (bool isDarkMode) {
                            // Handle theme change if needed
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
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
