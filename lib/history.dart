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
  String? userID; // Declare at the top to store the userID
  String _selectedFilter = 'Cashin'; // Default filter

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
      allLogs.sort((a, b) => (b['scannedTime'] as Timestamp)
          .compareTo(a['scannedTime'] as Timestamp));

      return allLogs;
    } catch (e) {
      debugPrint("Error fetching logs: $e");
      return [];
    }
  }

  Future<String?> _getUserID() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return null; // User is not authenticated, return null
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (userDoc.exists) {
      return userDoc.get('userID') as String?; // Ensure it returns a String? value
    } else {
      return null; // User document does not exist, return null
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    return WillPopScope(
      onWillPop: () async {
        return false; // Prevent the user from navigating back.
      },
      child: Scaffold(
        body: FutureBuilder<String?>(
          future: _getUserID(), // Fetch the userID asynchronously
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('User not authenticated or userID not found.'));
            }

            final userID = snapshot.data; // Get the userID from snapshot

            return Stack(
              children: [
                // Background container with the image
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
                // Foreground content container
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // History container
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pushes elements to opposite ends
                                children: [
                                  Padding(
                                    padding:  EdgeInsets.only(left: 10.0),
                                    child: Row(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        color: isDarkMode ? Colors.white : Colors.white, // Black for dark mode, white for light mode
                                        size: 30,
                                      ),
                                      SizedBox(width: 10.0),
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
                                  ),

                                  // Filter button
                              Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                  child: PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.filter_list,
                                      color: isDarkMode ? Colors.white : Colors.white, // Set color based on dark mode
                                    ),
                                    onSelected: (value) {
                                      setState(() {
                                        _selectedFilter = value;
                                      });
                                    },
                                    color: isDarkMode ? Colors.black87 : Colors.green.shade800,
                                    itemBuilder: (BuildContext context) {
                                      return ['Cashin', 'All', 'Login', 'Logout']
                                          .map((String choice) {
                                        return PopupMenuItem<String>(
                                          value: choice,
                                          child: Text(
                                            choice,
                                            style: TextStyle(color: Colors.white), // Set text color
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0),
                            // Logs list container
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6, // Set height as a fraction of the screen height
                              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                                future: _getCombinedLogs(userID), // Pass the userID
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text('Error: ${snapshot.error}'),
                                    );
                                  }

                                  final logs = snapshot.data ?? [];
                                  if (logs.isEmpty && _selectedFilter == 'All') {
                                    return const Center(child: Text('No logs available.'));
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
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogContainer(List<QueryDocumentSnapshot> logs) {
    List<Widget> filteredLogs = [];

    for (var log in logs) {
      final data = log.data() as Map<String, dynamic>;
      final timestamp = (data['scannedTime'] as Timestamp).toDate();
      final isLogin = data['scannedQR'] == 'http://www.FitTrack_Login.com';
      final isLogout = data['scannedQR'] == 'http://www.FitTrack_Logout.com';
      final isCashInLog = data.containsKey('amount');

      // Apply filter based on the selected filter
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
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Text(
                                isCashInLog
                                    ? "+ ₱ ${data['amount']?.toStringAsFixed(
                                    2) ?? '0.00'}"
                                    : "- ₱ 30.00",
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
                          transactionId: log.id, // Pass the document ID
                        ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    // Ensure we return the ListView outside of the loop
    return ListView(
      children: filteredLogs.isNotEmpty
          ? filteredLogs
          : [const Center(child: Text('No logs matching the filter.'))],
    );
  }
}
