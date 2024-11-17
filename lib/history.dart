import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedFilter = 'All'; // Default filter

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
      return userDoc.get('userID') as String?;
    } else {
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot>> _getCombinedLogs(String? userID) async {
    if (userID == null) return [];

    final loginQuery = FirebaseFirestore.instance
        .collection('logintime')
        .where('userID', isEqualTo: userID)
        .orderBy('scannedTime', descending: true)
        .get();

    final logoutQuery = FirebaseFirestore.instance
        .collection('logouttime')
        .where('userID', isEqualTo: userID)
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
        (b['scannedTime'] as Timestamp).compareTo(
            a['scannedTime'] as Timestamp));

    return allLogs;
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
                          // Align to the right
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              // Vertically center the amount
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                // Add some padding on the right side
                                child: Text(
                                  isCashInLog
                                      ? "+ ₱ ${data['amount']?.toStringAsFixed(
                                      2) ?? '0.00'}" // Amount for Cash-in
                                      : "- ₱ 30.00", // Fixed amount for Log-in
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0, // Make the text bigger
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ));
      }
    }

    // Ensure we return the ListView outside of the loop
    return ListView(
      children: filteredLogs.isNotEmpty
          ? filteredLogs
          : [const Center(child: Text('No logs matching the filter.'))],
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Prevents navigating back.
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
            FutureBuilder<String?>(
              future: _getUserID(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text(
                      'User not authenticated or userID not found.'));
                }

                final userID = snapshot.data;

                return Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.green[800],
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.history, color: Colors.green),
                                SizedBox(width: 8.0),
                                Text(
                                  'HISTORY',
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 18),
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                  Icons.filter_list, color: Colors.green),
                              onSelected: (value) {
                                setState(() {
                                  _selectedFilter = value;
                                });
                              },
                              itemBuilder: (BuildContext context) {
                                return ['All', 'Login', 'Logout', 'Cashin']
                                    .map((String choice) {
                                  return PopupMenuItem<String>(
                                    value: choice,
                                    child: Text(choice),
                                  );
                                }).toList();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      // Adds space between header and logs.
                      Expanded(
                        child: FutureBuilder<List<QueryDocumentSnapshot>>(
                          future: _getCombinedLogs(userID),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }
                            final logs = snapshot.data ?? [];
                            if (logs.isEmpty && _selectedFilter == 'All') {
                              return const Center(
                                  child: Text('No logs available.'));
                            }
                            return _buildLogContainer(logs);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}