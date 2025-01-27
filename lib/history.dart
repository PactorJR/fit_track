import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'history_desc.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? userID;
  String _selectedFilter = 'Cashin';
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<List<QueryDocumentSnapshot>> _getCombinedLogs(String? userID) async {
    if (userID == null) return [];

    try {
      final loginQuery = FirebaseFirestore.instance
          .collection('loghistory')
          .where('userID', isEqualTo: userID)
          .where('type', isEqualTo: "login")
          .orderBy('scannedTime', descending: true)
          .get();

      final logoutQuery = FirebaseFirestore.instance
          .collection('loghistory')
          .where('userID', isEqualTo: userID)
          .where('type', isEqualTo: "logout")
          .orderBy('scannedTime', descending: true)
          .get();

      final cashInQuery = FirebaseFirestore.instance
          .collection('cashinlogs')
          .where('userID', isEqualTo: userID)
          .orderBy('scannedTime', descending: true)
          .get();

      final results = await Future.wait([loginQuery, logoutQuery, cashInQuery]);

      final allLogs = [
        ...results[0].docs,
        ...results[1].docs,
        ...results[2].docs
      ];
      allLogs.sort((a, b) =>
          (b['scannedTime'] as Timestamp)
              .compareTo(a['scannedTime'] as Timestamp));

      return allLogs;
    } catch (e) {
      debugPrint("Error fetching logs: $e");
      return [];
    }
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);

    try {

      final userID = await _getUserID();

      if (userID != null) {

        final combinedLogs = await _getCombinedLogs(userID);


        setState(() {
          _logs = combinedLogs;
        });
      } else {
        debugPrint("No userID found.");
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetchAllData();
    print(_logs);
  }

  Future<String?> _getUserID() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return null;
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (userDoc.exists) {
      return userDoc.get(
          'userID') as String?;
    } else {
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double containerHeight;

    if (screenWidth <= 409) {
      containerHeight = screenHeight * 0.65;
    } else if (screenWidth >= 410) {
      containerHeight = screenHeight * 0.65;
    } else {
      containerHeight = screenHeight * 0.70;
    }

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body: FutureBuilder<String?>(
          future: _getUserID(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(
                child: Text('User not authenticated or userID not found.'),
              );
            }

            final userID = snapshot.data;

            return Stack(
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
                      padding: screenWidth < 360
                          ? const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10)
                          : const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      child: Column(
                        children: [

                          Container(
                            padding: screenWidth <= 409
                                ? const EdgeInsets.all(
                                8)
                                : const EdgeInsets.all(16),

                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.black38
                                  : Colors.green[800],

                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,

                                  children: [
                                    Padding(
                                      padding: screenWidth <= 409
                                          ? const EdgeInsets.only(
                                          left: 8.0)
                                          : const EdgeInsets.only(left: 10.0),

                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.history,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.white,

                                            size: screenWidth <= 409
                                                ? 24
                                                : 30,
                                          ),
                                          SizedBox(width: screenWidth <= 409
                                              ? 8.0
                                              : 10.0),

                                          Text(
                                            'HISTORY',
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.white,

                                              fontSize: screenWidth <= 409
                                                  ? 16
                                                  : 20,

                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Padding(
                                      padding: screenWidth <= 409
                                          ? const EdgeInsets.only(
                                          right: 8.0)
                                          : const EdgeInsets.only(right: 10.0),

                                      child: PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.filter_list,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors
                                              .white,
                                        ),
                                        onSelected: (value) {
                                          setState(() {
                                            _selectedFilter = value;
                                          });
                                        },
                                        color: isDarkMode
                                            ? Colors.black87
                                            : Colors.green.shade800,
                                        itemBuilder: (BuildContext context) {
                                          return [
                                            'Cashin',
                                            'All',
                                            'Login',
                                            'Logout'
                                          ]
                                              .map((String choice) {
                                            return PopupMenuItem<String>(
                                              value: choice,
                                              child: Text(
                                                choice,
                                                style: const TextStyle(
                                                    color: Colors
                                                        .white),
                                              ),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10.0),

                                SizedBox(
                                  height:containerHeight,
                                  child: FutureBuilder<
                                      List<QueryDocumentSnapshot>>(
                                    future: _getCombinedLogs(userID),

                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Text(
                                              'Error: ${snapshot.error}'),
                                        );
                                      }

                                      final logs = snapshot.data ?? [];
                                      if (logs.isEmpty &&
                                          _selectedFilter == 'All') {
                                        return const Center(
                                          child: Text(
                                            "No History at the Moment",
                                            style: TextStyle(
                                              color: Colors.white,

                                              fontSize: 16.0,

                                              fontWeight: FontWeight
                                                  .bold,
                                            ),
                                          ),
                                        );
                                      }
                                      return _buildLogContainer(logs);
                                    },
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
            );
          },
        ),
      ),
    );
  }


  Widget _buildLogContainer(List<QueryDocumentSnapshot> logs) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    List<Widget> filteredLogs = [];

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    for (var log in logs) {
      final data = log.data() as Map<String, dynamic>;
      final timestamp = (data['scannedTime'] as Timestamp).toDate();
      final isLogin = data['scannedQR'] == 'http://www.FitTrack_Login.com';
      final isLogout = data['scannedQR'] == 'http://www.FitTrack_Logout.com';
      final isCashInLog = data.containsKey('amount');


      if (_selectedFilter == 'All' ||
          (_selectedFilter == 'Login' && isLogin) ||
          (_selectedFilter == 'Logout' && isLogout) ||
          (_selectedFilter == 'Cashin' && isCashInLog)) {
        String title = '';
        String description = '';

        if (isLogin) {
          title = "Log-in";
          description =
          "Logged in by ${data['firstName'] ?? 'N/A'} ${data['lastName'] ??
              'N/A'} on ${DateFormat('EEEE, MMMM dd, yyyy hh:mm a').format(
              timestamp)}";
        } else if (isLogout) {
          title = "Log-out";
          description =
          "Logged out by ${data['firstName'] ?? 'N/A'} ${data['lastName'] ??
              'N/A'} on ${DateFormat('EEEE, MMMM dd, yyyy hh:mm a').format(
              timestamp)}";
        } else if (isCashInLog) {
          title = "Cash-in";
          description =
          "Amount: ₱${data['amount'] ?? 0}\nCashed-in by: ${data['adminName'] ??
              'Unknown Admin'} on ${DateFormat('EEEE, MMMM dd, yyyy hh:mm a')
              .format(timestamp)}";
        } else {
          title = "Unknown scan";
          description =
          "Unknown scan type on ${DateFormat('EEEE, MMMM dd, yyyy hh:mm a')
              .format(timestamp)}";
        }

        filteredLogs.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            height: isCashInLog ? 120.0 : 100.0,
            decoration: BoxDecoration(
              color: isLogin ? Colors.green : isLogout ? Colors.red : Colors
                  .blueAccent,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              title: Text(title, style: const TextStyle(color: Colors.white)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                      style: const TextStyle(color: Colors.white70)),
                  if (isCashInLog || isLogin)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              isCashInLog
                                  ? "+ ₱${(data['amount']?.toStringAsFixed(
                                  2)) ?? '0.00'}"
                                  : "- ₱30.00",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HistoryDescPage(
                          logData: data,
                          transactionId: log.id,
                        ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }


    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: filteredLogs.isNotEmpty
          ? ListView(
        children: filteredLogs,
      )
          : ListView(
        children: [
          Center(
            child: Text(
              "No History at the Moment",
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.white,

                fontSize: 16.0,

                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}