import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'users_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page_admin.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

class AlertsPageAdmin extends StatefulWidget {
  final Function? checkNewLogs;  // Optional parameter
  final Function? checkNewUsers; // Optional parameter

  AlertsPageAdmin({Key? key, this.checkNewLogs, this.checkNewUsers}) : super(key: key);

  @override
  State<AlertsPageAdmin> createState() => _AlertsPageAdminState();
}

class _AlertsPageAdminState extends State<AlertsPageAdmin> {
  List<int> shownNotificationIds = []; // Store shown notification IDs

  @override
  void initState() {
    super.initState();
  }

  String selectedFilter = 'All';
  String? selectedDocId;

  bool hasData(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.hasData && snapshot.data!.docs.isNotEmpty;
  }

  Future<void> markAsSeen(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'seen': true});
    } catch (e) {
      // Handle error if update fails
      print('Error marking user as seen: $e');
    }
  }

  Widget detectNewUsers(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('seen', isEqualTo: false)
          .where('registerTime', isLessThan: Timestamp.fromDate(DateTime.now()))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Column(
            children: snapshot.data!.docs.map((doc) {
              Timestamp registerTime = doc['registerTime'];
              DateTime registerDate = registerTime.toDate();

              return GestureDetector(
                onTap: () async {
                  String userId = doc.id;
                  print(userId);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UsersAdminPage(userId: userId),
                    ),
                  );
                  await markAsSeen(userId);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.yellow,
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'NEW USER DETECTED:',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Username: ${doc['firstName']} ${doc['lastName']}',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Registration Date: ${DateFormat('MMMM dd, yyyy h:mm:ss a').format(registerDate)}',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }

        return SizedBox.shrink();
      },
    );
  }


  Widget detectLogs(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('loghistory')
          .where('seen', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Column(
            children: snapshot.data!.docs.map((doc) {
              String docId = doc.id; // Unique document ID
              bool seen = doc['seen'] ?? false; // Default to false if 'seen' is not set
              String type = doc['type'] ?? 'unknown'; // Default to 'unknown' if 'type' is missing
              Timestamp? scannedTime = doc['scannedTime'];
              DateTime logDate = scannedTime?.toDate() ?? DateTime.now(); // Use current time if 'scannedTime' is null

              Color backgroundColor = type == 'login' ? Colors.blue[600]! : Colors.red[600]!;
              Color selectedColor = type == 'login' ? Colors.blue[300]! : Colors.red[300]!;
              Color textColor = Colors.white;

              return GestureDetector(
                onTap: () async {
                  // Navigate and pass docId to MyAdminHomePage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyAdminHomePage(
                        title: 'Admin History',
                        selectedIndex: 2, // Navigate to the Alerts tab index
                        docId: docId, // Pass the docId
                      ),
                    ),
                  );
                  await _updateSeenLogHistory(docId); // Mark the log as seen
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      width: 2.0,
                      color: selectedDocId == docId ? selectedColor : backgroundColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            type == 'login' ? Icons.login : Icons.logout,
                            color: textColor,
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            type == 'login' ? 'USER LOGGED IN:' : 'USER LOGGED OUT:',
                            style: TextStyle(color: textColor, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Username: ${doc['firstName'] ?? 'N/A'} ${doc['lastName'] ?? 'N/A'}',  // Use 'N/A' if null
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${type == 'login' ? 'Login' : 'Logout'} Time: ${DateFormat('MMMM dd, yyyy h:mm:ss a').format(logDate)}',
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'User ID: ${doc['userID'] ?? 'N/A'}', // Use 'N/A' if null
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      const SizedBox(height: 4.0),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

// Refactored function to update 'seen' value
  Future<void> _updateSeenLogHistory(String docId) async {
    try {
      // Update the 'seen' value to true in Firestore when tapped
      await FirebaseFirestore.instance
          .collection('loghistory')
          .doc(docId)
          .update({'seen': true});
    } catch (e) {
      // Handle any errors that occur during the update
      print("Error updating seen field: $e");
    }
  }

  Widget detectCashIns(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Text(
        'No admin logged in.',
        style: TextStyle(color: Colors.red, fontSize: 16),
      );
    }

    String currentAdminId = currentUser.uid; // The ID of the currently logged-in admin

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cashinlogs')
          .where('seen', isEqualTo: false)
          .where('adminID', isEqualTo: currentAdminId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Column(
            children: snapshot.data!.docs.map((doc) {
              Timestamp scannedTime = doc['scannedTime'];
              DateTime scannedDate = scannedTime.toDate();

              return GestureDetector(
                onTap: () async {
                  // Navigate to Admin Home Page and update log history
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyAdminHomePage(
                        title: 'Admin Dashboard',
                        selectedIndex: 2, // Navigate to the Alerts tab index
                      ),
                    ),
                  );
                  await _updateSeenCashIn(doc.id);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.yellow[700],
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Colors.green,
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'CASH-IN DETECTED:',
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Username: ${doc['userName']}',
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Amount: \$${doc['amount']}',
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Time: ${DateFormat('MMMM dd, yyyy h:mm:ss a').format(scannedDate)}',
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Future<void> _updateSeenCashIn(String docId) async {
    try {
      // Update the 'seen' value to true in Firestore when tapped
      await FirebaseFirestore.instance
          .collection('cashinlogs')
          .doc(docId)
          .update({'seen': true});
    } catch (e) {
      // Handle any errors that occur during the update
      print("Error updating seen field: $e");
    }
  }

  Widget getFilteredContent() {
    if (selectedFilter == 'New User') {
      Widget newUsersWidget = detectNewUsers(context);
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('seen', isEqualTo: false)
            .where('registerTime', isLessThan: Timestamp.fromDate(DateTime.now()))
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No new user found.', style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          return newUsersWidget;
        },
      );
    } else if (selectedFilter == 'Cash-ins') {
      Widget cashInsWidget = detectCashIns(context);
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cashinlogs')
            .where('seen', isEqualTo: false)
            .where('adminID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No cash-in logs found.', style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          return cashInsWidget;
        },
      );
    } else if (selectedFilter == 'Logins') {
      Widget loginsWidget = detectLogs(context);
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('loghistory')
            .where('type', isEqualTo: "login")
            .where('seen', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No login records found.', style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          if (snapshot.hasData) {
            // Optionally process and display data from snapshot if needed.
            return loginsWidget;
          }
          return const Center(child: Text('Unexpected state encountered.'));
        },
      );
    } else if (selectedFilter == 'Logouts') {
      Widget loginsWidget = detectLogs(context);
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('loghistory')
            .where('type', isEqualTo: "logout")
            .where('seen', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No logout records found.', style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          if (snapshot.hasData) {
            // Optionally process and display data from snapshot if needed.
            return loginsWidget;
          }
          return const Center(child: Text('Unexpected state encountered.'));
        },
      );
    }  else if (selectedFilter == 'All') {
      return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('seen', isEqualTo: false)
            .snapshots(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('cashinlogs')
                .where('seen', isEqualTo: false)
                .where('adminID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, cashinsSnapshot) {
              if (cashinsSnapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              return StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('loghistory')
                    .where('type', isEqualTo: "login")
                    .where('seen', isEqualTo: false)
                    .snapshots(),
                builder: (context, loginsSnapshot) {
                  if (loginsSnapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('loghistory')
                        .where('type', isEqualTo: "logout")
                        .where('seen', isEqualTo: false)
                        .snapshots(),
                    builder: (context, logoutsSnapshot) {
                      if (logoutsSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      // Check if all collections are empty
                      bool allEmpty = usersSnapshot.hasData && usersSnapshot.data!.docs.isEmpty &&
                          cashinsSnapshot.hasData && cashinsSnapshot.data!.docs.isEmpty &&
                          loginsSnapshot.hasData && loginsSnapshot.data!.docs.isEmpty &&
                          logoutsSnapshot.hasData && logoutsSnapshot.data!.docs.isEmpty;

                      if (allEmpty) {
                        return Center(child: Text('No alerts found.', style: TextStyle(color: Colors.white, fontSize: 18)));
                      }

                      // If there's data in any of the collections, show respective widgets
                      return Column(
                        children: [
                          detectNewUsers(context),
                          detectCashIns(context),
                          detectLogs(context),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    } else {
      return Column(
        children: [
          detectNewUsers(context),
          detectCashIns(context),
          detectLogs(context),
        ],
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    isDarkMode
                        ? 'assets/images/dark_bg.png'
                        : 'assets/images/bg.png', // Switch background image based on dark mode
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black38
                            : Colors.green[800], // Set color based on dark mode
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications,
                                    size: 30, // Larger size for the icon
                                    color: isDarkMode ? Colors.white : Colors.white, // Black for dark mode, white for light mode
                                  ),
                                  SizedBox(width: 8.0),
                                  Text(
                                    'ALERTS',
                                    style: TextStyle(
                                      fontSize: 20, // Adjust the font size as needed
                                      color: isDarkMode ? Colors.white : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              // Dropdown button for filter
                              DropdownButton<String>(
                                value: selectedFilter,
                                icon: Icon(
                                  Icons.filter_alt,
                                  size: 30, // Larger size for the icon
                                  color: isDarkMode ? Colors.white : Colors.white, // Black for dark mode, white for light mode
                                ),
                                onChanged: (String? newFilter) {
                                  if (newFilter != null) {
                                    setState(() {
                                      selectedFilter = newFilter;
                                    });
                                  }
                                },
                                style: TextStyle(
                                  color: themeProvider.isDarkMode ? Colors.black : Colors.black, // Dynamic color
                                  fontSize: 16, // Set your desired font size
                                ), // White text when dropdown is closed
                                dropdownColor: themeProvider.isDarkMode ? Colors.black : Colors.green[800], // Dynamic color // Background color of the dropdown
                                items: [
                                  'All',
                                  'New User',
                                  'Cash-ins',
                                  'Logins',
                                  'Logouts'
                                ].map<DropdownMenuItem<String>>((String filter) {
                                  return DropdownMenuItem<String>(
                                    value: filter,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16), // Softer edges for items
                                        color: Colors.white, // Background color for items
                                      ),
                                      child: Text(
                                        filter,
                                        style: TextStyle(color: Colors.black), // Black text for items
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          getFilteredContent(), // Dynamically display the content based on the selected filter
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
    );
  }
}
