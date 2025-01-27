import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'users_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'history_desc_admin.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

class HistoryPageAdmin extends StatefulWidget {
  final String? docId;

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
    selectedDocId = widget.docId;
  }

  bool _isLoading = true;

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    getFilteredContent();
    try {
      await Future.wait([]);
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetchAllData();
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
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Column(
            children: snapshot.data!.docs.map((doc) {
              bool seen = doc['seen'] ?? false;
              Timestamp registerTime = doc['registerTime'];
              DateTime registerDate = registerTime.toDate();
              Color textColor = seen ? Colors.grey.shade400 : Colors.white;

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
                        'Registration Date: ${DateFormat(
                            'MMMM dd, yyyy h:mm:ss a').format(registerDate)}',
                        style: TextStyle(color: textColor, fontSize: 14),
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

              bool isSelected = selectedDocId == docId;
              Color backgroundColor =
              type == 'login' ? Colors.blue[600]! : Colors.red[600]!;
              Color selectedColor =
              type == 'login' ? Colors.blue[300]! : Colors.red[300]!;
              Color textColor = isSelected
                  ? Colors.white
                  : (seen ? Colors.grey.shade400 : Colors.white);

              return GestureDetector(
                  onTap: () async {
                    if (selectedDocId != docId) {
                      Future.delayed(Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            selectedDocId = docId;
                          });
                        }
                      });
                    }

                    final logData = doc.data() as Map<String, dynamic>?;
                    final transactionId = doc.id;

                    if (transactionId != null && docId.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('loghistory')
                          .doc(transactionId)
                          .update({'seen': true});
                    }

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
                            type == 'login'
                                ? 'USER LOGGED IN:'
                                : 'USER LOGGED OUT:',
                            style: TextStyle(color: textColor, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Username: ${doc['firstName'] ?? 'N/A'} ${doc['lastName'] ?? 'N/A'}',
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'User ID: ${doc['userID'] ?? 'N/A'}',
                        style: TextStyle(color: textColor, fontSize: 14),
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



  Widget detectCashIns(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Text(
        'No admin logged in.',
        style: TextStyle(color: Colors.red, fontSize: 16),
      );
    }

    String currentAdminId = currentUser.uid;

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
              String docId = doc.id;
              bool isSelected = selectedDocId == docId;
              bool seen = doc['seen'] ?? false;
              Color textColor = seen ? Colors.grey.shade700 : Colors.black;

              return GestureDetector(
                onTap: () async {
                  if (selectedDocId != docId) {
                    Future.delayed(Duration(seconds: 2), () {
                      if (mounted) {
                        setState(() {
                          selectedDocId = docId;
                        });
                      }
                    });
                  }

                  final logData = doc.data() as Map<String, dynamic>?;
                  final transactionId = doc.id;

                  if (transactionId != null && docId.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('cashinlogs')
                        .doc(transactionId)
                        .update({'seen': true});
                  }

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
                    print("Error: logData is null.");
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[300] : Colors.yellow[700],
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
                              color: textColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Username: ${doc['userName']}',
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Amount: \$${doc['amount']}',
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

  Widget getFilteredContent() {
    if (selectedFilter == 'New User') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where(
            'registerTime', isLessThan: Timestamp.fromDate(DateTime.now()))
            .orderBy('registerTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('An error occurred: ${snapshot.error.toString()}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No new user found.',
                style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          return detectNewUsers(context);
        },
      );
    } else if (selectedFilter == 'Cash-ins') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cashinlogs')
            .where('adminID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy('scannedTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('An error occurred: ${snapshot.error.toString()}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No cash-in logs found.',
                style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          return detectCashIns(context);
        },
      );
    } else if (selectedFilter == 'Logins') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('loghistory')
            .where('type', isEqualTo: "login")
            .orderBy('scannedTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('An error occurred: ${snapshot.error.toString()}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No login records found.',
                style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          return detectLogs(context, 'login');
        },
      );
    } else if (selectedFilter == 'Logouts') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('loghistory')
            .where('type', isEqualTo: "logout")
            .orderBy('scannedTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('An error occurred: ${snapshot.error.toString()}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No logout records found.',
                style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          return detectLogs(context, 'logout');
        },
      );
    } else if (selectedFilter == 'All') {
      return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('registeredTime', descending: true)
            .snapshots(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('cashinlogs')
                .where(
                'adminID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .orderBy('scannedTime', descending: true)
                .snapshots(),
            builder: (context, cashinsSnapshot) {
              return StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('loghistory')
                    .where('type', isEqualTo: "login")
                    .orderBy('scannedTime', descending: true)
                    .snapshots(),
                builder: (context, loginsSnapshot) {
                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('loghistory')
                        .where('type', isEqualTo: "logout")
                        .orderBy('scannedTime', descending: true)
                        .snapshots(),
                    builder: (context, logoutsSnapshot) {
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
    bool isDarkMode = Provider
        .of<ThemeProvider>(context)
        .isDarkMode;
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;

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
                        height: containerHeight,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.black38
                              : Colors.green[800],
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
                                        Icons.history,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.white,
                                        size: screenWidth < 360 ? 24 : 30,
                                      ),
                                      SizedBox(
                                          width: screenWidth < 360 ? 8 : 10),
                                      Text(
                                        'HISTORY',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.white,
                                          fontSize: screenWidth < 360 ? 12 : 16,
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
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.white,
                                        ),
                                        itemBuilder: (BuildContext context) {
                                          return [
                                            'All',
                                            'New User',
                                            'Cash-ins',
                                            'Logins',
                                            'Logouts'
                                          ].map((String filter) {
                                            return PopupMenuItem<String>(
                                              value: filter,
                                              child: Text(
                                                filter,
                                                style: TextStyle(
                                                  color: isDarkMode ? Colors
                                                      .white : Colors.black,
                                                ),
                                              ),
                                            );
                                          }).toList();
                                        },
                                        offset: Offset(10, 0),
                                        padding: EdgeInsets.all(0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              16),
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
