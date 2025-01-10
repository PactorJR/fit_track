import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'users_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'history_desc_admin.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';


class HistoryPageAdmin extends StatefulWidget {
  final String? docId; // Accept docId as a parameter

  HistoryPageAdmin({Key? key, this.docId}) : super(key: key);

  @override
  State<HistoryPageAdmin> createState() => _HistoryPageAdminState();
}

class _HistoryPageAdminState extends State<HistoryPageAdmin> {
  String selectedFilter = 'All';
  String? selectedDocId;

  @override
  void initState() {
    super.initState();
    selectedDocId = widget.docId; // Set the initial selectedDocId to the passed docId
  }

  bool hasData(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.hasData && snapshot.data!.docs.isNotEmpty;
  }

  Widget detectNewUsers(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('registerTime', isLessThan: Timestamp.fromDate(DateTime.now()))
          .snapshots(),
      builder: (context, snapshot) {

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        // If there are users
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Column(
            children: snapshot.data!.docs.map((doc) {
              bool seen = doc['seen'] ?? false; // Default to false if 'seen' is not set
              Timestamp registerTime = doc['registerTime'];
              DateTime registerDate = registerTime.toDate();
              Color textColor = seen ? Colors.grey.shade400 : Colors.white; // Set color based on 'seen' value

              return GestureDetector(
                onTap: () {
                  String userId = doc.id;
                  print(userId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UsersAdminPage(userId: userId),
                    ),
                  );
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
                            style: TextStyle(color: textColor, fontSize: 16),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Username: ${doc['firstName']} ${doc['lastName']}',
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Registration Date: ${DateFormat('MMMM dd, yyyy h:mm:ss a').format(registerDate)}',
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }

        // Default case if no data
        return SizedBox.shrink();
      },
    );
  }

  Widget detectLogs(BuildContext context, String logType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('loghistory')
          .where('type', isEqualTo: logType)
          .where('scannedQR', isEqualTo: logType == "login"
          ? "http://www.FitTrack_Login.com"
          : "http://www.FitTrack_Logout.com")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Column(
            children: snapshot.data!.docs.map((doc) {
              String docId = doc.id;
              bool seen = doc['seen'] ?? false;
              String type = doc['type'] ?? 'unknown';
              Timestamp scannedTime = doc['scannedTime'];
              DateTime logDate = scannedTime.toDate();

              bool isSelected = selectedDocId == docId;
              Color backgroundColor =
              type == 'login' ? Colors.blue[600]! : Colors.red[600]!;
              Color selectedColor =
              type == 'login' ? Colors.blue[300]! : Colors.red[300]!;
              Color textColor = isSelected
                  ? Colors.white
                  : (seen ? Colors.grey.shade400 : Colors.white);

              return GestureDetector(
                onTap: () {
                  if (selectedDocId != docId) {
                    setState(() {
                      selectedDocId = docId;
                    });
                  }
                  final logData = doc.data() as Map<String, dynamic>?; // Cast to the correct type
                  final transactionId = doc.id; // Get the document ID

                  if (logData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryDescAdminPage(
                          logData: logData,
                          transactionId: transactionId,
                        ),
                      ),
                    );
                  } else {
                    // Handle the case where logData is null if needed
                    print("Error: logData is null.");
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isSelected ? selectedColor : backgroundColor,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 2.0,
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
                        'Username: ${doc['firstName']} ${doc['lastName']}',
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${type == 'login' ? 'Login' : 'Logout'} Time: ${DateFormat('MMMM dd, yyyy h:mm:ss a').format(logDate)}',
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'User ID: ${doc['userID']}',
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }

        return Center(
          child: Text(
            'No $logType logs available.',
            style: TextStyle(color: Colors.grey),
          ),
        );
      },
    );
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
          .where('adminID', isEqualTo: currentAdminId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Column(
            children: snapshot.data!.docs.map((doc) {
              String docId = doc.id; // Unique document ID
              bool isSelected = selectedDocId == docId;
              bool seen = doc['seen'] ?? false; // Default to false if 'seen' is not set
              Timestamp scannedTime = doc['scannedTime'];
              DateTime scannedDate = scannedTime.toDate();

              return GestureDetector(
                onTap: () {
                  if (selectedDocId != docId) {
                    setState(() {
                      selectedDocId = docId;
                    });
                  }
                  final logData = doc.data() as Map<String, dynamic>?; // Cast to the correct type
                  final transactionId = doc.id; // Get the document ID

                  if (logData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryDescAdminPage(
                          logData: logData,
                          transactionId: transactionId,
                        ),
                      ),
                    );
                  } else {
                    // Handle the case where logData is null if needed
                    print("Error: logData is null.");
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[300] : Colors.yellow[700], // Highlight selected container
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2.0,
                    ),
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
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Username: ${doc['userName']}',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Amount: \$${doc['amount']}',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Scanned Time: ${DateFormat('MMMM dd, yyyy h:mm:ss a').format(scannedDate)}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        } else {
          return Text('No cash-in logs found.');
        }
      },
    );
  }

  Widget getFilteredContent() {
    if (selectedFilter == 'New User') {
      Widget newUsersWidget = detectNewUsers(context);
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
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
            .where('adminID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No cash-in logs found.', style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          return cashInsWidget;
        },
      );
    } else if (selectedFilter == 'Logins') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('loghistory')
            .where('type', isEqualTo: "login")
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error.toString()}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No login records found.', style: TextStyle(color: Colors.white, fontSize: 18)));
          } else {
            // If data exists, pass it to your widget for display
            return detectLogs(context, 'login');
          }
        },
      );
    } else if (selectedFilter == 'Logouts') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('loghistory')
            .where('type', isEqualTo: "logout")
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error.toString()}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No logout records found.', style: TextStyle(color: Colors.white, fontSize: 18)));
          } else {
            // If data exists, pass it to your widget for display
            return detectLogs(context, 'logout');
          }
        },
      );
    } else if (selectedFilter == 'All') {
      return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('cashinlogs')
                .where('adminID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, cashinsSnapshot) {

              return StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('loghistory')
                    .where('type', isEqualTo: "login")
                    .snapshots(),
                builder: (context, loginsSnapshot) {

                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('loghistory')
                        .where('type', isEqualTo: "logout")
                        .snapshots(),
                    builder: (context, logoutsSnapshot) {

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
                          detectLogs(context, 'login'),
                          detectLogs(context, 'logout'),
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
          detectLogs(context, 'login'),
          detectLogs(context, 'logout'),
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
                      padding: const EdgeInsets.all(8.0),
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
                                    Icons.history,
                                    color: isDarkMode ? Colors.white : Colors.white, // Black for dark mode, white for light mode
                                    size: 30,
                                  ),
                                   SizedBox(width: 8.0),
                                   Text(
                                    'HISTORY',
                                     style: TextStyle(
                                       color: isDarkMode ? Colors.white : Colors.white, // White for dark mode, black for light mode
                                       fontSize: 20,
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
                                  color: isDarkMode ? Colors.white : Colors.white, // Black for dark mode, white for light mode
                                  size: 30,
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
                                dropdownColor: themeProvider.isDarkMode ? Colors.black : Colors.green[800], // Background color of the dropdown
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
                          const SizedBox(height: 8.0),
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
