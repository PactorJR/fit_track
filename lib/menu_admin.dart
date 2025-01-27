import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings.dart';
import 'users_admin.dart';
import 'profile.dart';
import 'graphs_admin.dart';
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
        return snapshot.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text('No user logged in'));
    }

    final userId = user.uid;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              themeProvider.isDarkMode
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
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('No user data found.'));
            } else {
              var userData = snapshot.data!;
              return ListView(
                children: [
                  Container(
                    color: themeProvider.isDarkMode
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
                                backgroundImage: _userData != null &&
                                    _userData['profileImage'] != null &&
                                    _userData['profileImage'].isNotEmpty
                                    ? NetworkImage(_userData['profileImage'])
                                    : AssetImage('assets/images/Icon$profileIconIndex.png') as ImageProvider,
                                child: _userData != null &&
                                    _userData['profileImage'] != null &&
                                    _userData['profileImage'].isNotEmpty
                                    ? null
                                    : null,
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
                          "Student ID: ${userData['userID'] ?? 'Not available'}",
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
