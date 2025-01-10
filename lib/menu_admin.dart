import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings.dart';
import 'users_admin.dart';
import 'profile.dart';
import 'graphs_admin.dart'; // Ensure this file exists and is defined correctly
import 'scan_qr.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'member_benefits.dart';
import 'equip_admin.dart';
import 'files_admin.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider
        .of<ThemeProvider>(context)
        .isDarkMode;
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text('No user logged in'));
    }

    final userId = user.uid;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            // Switch between background images based on dark mode
            image: AssetImage(
              themeProvider.isDarkMode
                  ? 'assets/images/dark_bg.png' // Dark mode background
                  : 'assets/images/bg.png', // Light mode background
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUserData(), // Fetch user data asynchronously
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('No user data found.'));
            } else {
              var userData = snapshot.data!;
              return ListView(
                children: [
                  // User Profile Section
                  Container(
                    color: themeProvider.isDarkMode
                        ? Colors.black38 // Dark mode container color
                        : Colors.green[700]?.withOpacity(0.9),
                    padding: EdgeInsets.all(16.0),
                    child: Column(
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
                          "Student ID: ${userData['userID'] ??
                              'Not available'}",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified, color: Colors.amberAccent),
                            SizedBox(width: 5),
                            Text(
                              "You are a member!",
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
                                  MaterialPageRoute(
                                    builder: (context) => MemberBenefitsPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                isDarkMode ? Colors.black38 : Colors.white,
                                foregroundColor:
                                isDarkMode ? Colors.white : Colors.green,
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
                  // Menu Items Section
                  _buildMenuItem(context, icon: Icons.qr_code,
                      label: "Scan QR",
                      page: ScanPage(),
                    isDarkMode: isDarkMode,
                  ),
                  _buildMenuItem(context, icon: Icons.people,
                      label: "Users",
                      page: UsersAdminPage(),
                    isDarkMode: isDarkMode,
                  ),
                  _buildMenuItem(context, icon: Icons.person,
                      label: "Profile",
                      page: ProfilePage(),
                    isDarkMode: isDarkMode,
                  ),
                  _buildMenuItem(context, icon: Icons.edit_note_outlined,
                      label: "Reports",
                      page: GraphsAdminPage(),
                    isDarkMode: isDarkMode,
                  ),
                  _buildMenuItem(context, icon: Icons.fitness_center,
                    label: "Equipments",
                    page: EquipAdminPage(),
                    isDarkMode: isDarkMode,
                  ),
                  _buildMenuItem(context, icon: Icons.folder,
                    label: "Files",
                    page: FilesAdminPage(),
                    isDarkMode: isDarkMode,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    label: "Settings",
                    page: SettingsPage(
                      isDarkMode: themeProvider.isDarkMode,
                      onThemeChanged: (bool isDarkMode) {
                        // Handle theme change if needed
                      },
                    ),
                    isDarkMode: isDarkMode,
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

    // Helper method to build each menu item
  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String label,
    required Widget page,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      child: Material(
        color: Colors.transparent,  // Ensures background is transparent
        elevation: 0,  // Shadow effect when pressed
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.transparent, // Keeps the background transparent when not pressed
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: () async {
              // Wait for animation to complete before navigating
              await Future.delayed(const Duration(milliseconds: 100));  // Delay to allow animation to complete
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
            },  // GestureDetector handles the actual tap event
            child: ListTile(
              leading: Icon(
                icon,
                color: isDarkMode ? Colors.white : Colors.green, // Icon color based on dark mode
              ),
              title: Text(
                label,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black), // Text color based on dark mode
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: isDarkMode ? Colors.white : Colors.green[800], // Trailing icon color based on dark mode
              ),
            ),
          ),
        ),
      ),
    );
  }
}
