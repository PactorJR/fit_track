import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'users_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page_admin.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

class AlertsPageAdmin extends StatefulWidget {
  final Function? checkNewLogs;
  final Function? checkNewUsers;

  AlertsPageAdmin({Key? key, this.checkNewLogs, this.checkNewUsers}) : super(key: key);

  @override
  State<AlertsPageAdmin> createState() => _AlertsPageAdminState();
}

class _AlertsPageAdminState extends State<AlertsPageAdmin> {
  List<int> shownNotificationIds = [];

  @override
  void initState() {
    super.initState();
  }

  bool _isLoading = true;

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    getFilteredContent();
    try {
      await Future.wait([
      ]);
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetchAllData();
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
                        'Registration Date: ${DateFormat(
                            'MMMM dd, yyyy h:mm:ss a').format(registerDate)}',
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


  Widget detectLogins(BuildContext context) {
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
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Column(
            children: snapshot.data!.docs.map((doc) {
              String docId = doc.id;
              bool seen = doc['seen'] ??
                  false;
              String type = doc['type'] ??
                  'unknown';
              Timestamp? scannedTime = doc['scannedTime'];
              DateTime logDate = scannedTime?.toDate() ??
                  DateTime.now();

              Color backgroundColor = type == 'login'
                  ? Colors.blue[600]!
                  : Colors.red[600]!;
              Color selectedColor = type == 'login' ? Colors.blue[300]! : Colors
                  .red[300]!;
              Color textColor = Colors.white;

              return GestureDetector(
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MyAdminHomePage(
                            title: 'Admin History',
                            selectedIndex: 2,
                            docId: docId,
                          ),
                    ),
                  );
                  await _updateSeenLogHistory(docId);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      width: 2.0,
                      color: selectedDocId == docId
                          ? selectedColor
                          : backgroundColor,
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
                            type == 'login'
                                ? 'USER LOGGED IN:'
                                : 'USER LOGGED OUT:',
                            style: TextStyle(color: textColor, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Username: ${doc['firstName'] ??
                            'N/A'} ${doc['lastName'] ?? 'N/A'}',
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${type == 'login'
                            ? 'Login'
                            : 'Logout'} Time: ${DateFormat(
                            'MMMM dd, yyyy h:mm:ss a').format(logDate)}',
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

  Widget detectLogouts(BuildContext context) {
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
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Column(
            children: snapshot.data!.docs.map((doc) {
              String docId = doc.id;
              bool seen = doc['seen'] ??
                  false;
              String type = doc['type'] ??
                  'unknown';
              Timestamp? scannedTime = doc['scannedTime'];
              DateTime logDate = scannedTime?.toDate() ??
                  DateTime.now();

              Color backgroundColor = type == 'login'
                  ? Colors.blue[600]!
                  : Colors.red[600]!;
              Color selectedColor = type == 'login' ? Colors.blue[300]! : Colors
                  .red[300]!;
              Color textColor = Colors.white;

              return GestureDetector(
                onTap: () async {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MyAdminHomePage(
                            title: 'Admin History',
                            selectedIndex: 2,

                            docId: docId,
                          ),
                    ),
                  );
                  await _updateSeenLogHistory(docId);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      width: 2.0,
                      color: selectedDocId == docId
                          ? selectedColor
                          : backgroundColor,
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
                            type == 'login'
                                ? 'USER LOGGED IN:'
                                : 'USER LOGGED OUT:',
                            style: TextStyle(color: textColor, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Username: ${doc['firstName'] ??
                            'N/A'} ${doc['lastName'] ?? 'N/A'}',

                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${type == 'login'
                            ? 'Login'
                            : 'Logout'} Time: ${DateFormat(
                            'MMMM dd, yyyy h:mm:ss a').format(logDate)}',
                        style: TextStyle(color: textColor, fontSize: 14),
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


  Future<void> _updateSeenLogHistory(String docId) async {
    try {

      await FirebaseFirestore.instance
          .collection('loghistory')
          .doc(docId)
          .update({'seen': true});
    } catch (e) {

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

    String currentAdminId = currentUser
        .uid;

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

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const MyAdminHomePage(
                        title: 'Admin Dashboard',
                        selectedIndex: 2,
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

      await FirebaseFirestore.instance
          .collection('cashinlogs')
          .doc(docId)
          .update({'seen': true});
    } catch (e) {

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
            .orderBy('registerTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No new user found.',
                style: TextStyle(color: Colors.white, fontSize: 18)));
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
            .orderBy('scannedTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No cash-in logs found.',
                style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          return cashInsWidget;
        },
      );
    } else if (selectedFilter == 'Logins') {
      Widget loginsWidget = detectLogins(context);
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('loghistory')
            .where('type', isEqualTo: "login")
            .where('seen', isEqualTo: false)
            .orderBy('scannedTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No login records found.',
                style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          if (snapshot.hasData) {

            return loginsWidget;
          }
          return const Center(child: Text('Unexpected state encountered.'));
        },
      );
    } else if (selectedFilter == 'Logouts') {
      Widget logoutsWidget = detectLogouts(context);
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('loghistory')
            .where('type', isEqualTo: "logout")
            .where('seen', isEqualTo: false)
            .orderBy('scannedTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No logout records found.',
                style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          if (snapshot.hasData) {

            return logoutsWidget;
          }
          return const Center(child: Text('Unexpected state encountered.'));
        },
      );
    } else if (selectedFilter == 'All') {
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
                .where(
                'adminID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
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
                  if (loginsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('loghistory')
                        .where('type', isEqualTo: "logout")
                        .where('seen', isEqualTo: false)
                        .snapshots(),
                    builder: (context, logoutsSnapshot) {
                      if (logoutsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }


                      bool allEmpty = usersSnapshot.hasData &&
                          usersSnapshot.data!.docs.isEmpty &&
                          cashinsSnapshot.hasData &&
                          cashinsSnapshot.data!.docs.isEmpty &&
                          loginsSnapshot.hasData &&
                          loginsSnapshot.data!.docs.isEmpty &&
                          logoutsSnapshot.hasData &&
                          logoutsSnapshot.data!.docs.isEmpty;

                      if (allEmpty) {
                        return Center(child: Text('No alerts found.',
                            style: TextStyle(
                                color: Colors.white, fontSize: 18)));
                      }


                      return Column(
                        children: [
                          detectNewUsers(context),
                          detectCashIns(context),
                          detectLogins(context),
                          detectLogouts(context),
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
          detectLogins(context),
          detectLogouts(context),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider
        .of<ThemeProvider>(context)
        .isDarkMode;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double containerHeight;

    if (screenWidth <= 409) {
      containerHeight = screenHeight * 0.65;
    } else if (screenWidth >= 410) {
      containerHeight = screenHeight * 0.75;
    } else {
      containerHeight = screenHeight * 0.70;
    }
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
                        : 'assets/images/bg.png',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.0),
                        height: containerHeight,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black38 : Colors.green[800],

                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,

                              children: [

                                Padding(
                                  padding: screenWidth < 360
                                      ? EdgeInsets.only(left: 8)
                                      : EdgeInsets.only(left: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.notifications,
                                        size: screenWidth < 360 ? 24 : 30,
                                        color: isDarkMode ? Colors.white : Colors.white,
                                      ),
                                      SizedBox(width: screenWidth < 360 ? 8 : 10),

                                      Text(
                                        'Alerts',
                                        style: TextStyle(
                                          fontSize: screenWidth < 360 ? 12 : 16,
                                          color: isDarkMode ? Colors.white : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: screenWidth < 360
                                      ? EdgeInsets.only(right: 8)
                                      : EdgeInsets.only(right: 10),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 8.0),
                                      PopupMenuButton<String>(
                                        onSelected: (String newFilter) {
                                          setState(() {
                                            selectedFilter = newFilter;
                                          });
                                        },
                                        icon: Icon(
                                          Icons.filter_alt,
                                          size: screenWidth < 360 ? 20 : 25,
                                          color: isDarkMode ? Colors.white : Colors.white,
                                        ),
                                        itemBuilder: (BuildContext context) {
                                          return [
                                            'All', 'New User', 'Cash-ins', 'Logins', 'Logouts'
                                          ].map((String filter) {
                                            return PopupMenuItem<String>(
                                              value: filter,
                                              child: Text(
                                                filter,
                                                style: TextStyle(
                                                  color: isDarkMode ? Colors.white : Colors.black,
                                                ),
                                              ),
                                            );
                                          }).toList();
                                        },
                                        offset: Offset(10, 0),
                                        padding: EdgeInsets.all(0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenWidth < 360 ? 4 : 5),
                            Expanded(
                              child: SingleChildScrollView(
                                child: getFilteredContent(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
