import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'users_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';

Widget detectNewUsers(BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .where('registerTime', isLessThan: Timestamp.fromDate(DateTime.now()))
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      }
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
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      }
      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      }

      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
        return Column(
          children: snapshot.data!.docs.map((doc) {
            bool seen = doc['seen'] ?? false; // Default to false if 'seen' is not set
            Timestamp scannedTime = doc['scannedTime'];
            DateTime scannedDate = scannedTime.toDate();
            Color textColor = seen ? Colors.grey.shade700 : Colors.black; // Set color based on 'seen' value

            return Container(
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
                        style: TextStyle(color: textColor, fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'Username: ${doc['userName']}',
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'Amount: \$${doc['amount']}',
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'Scanned Time: ${DateFormat('MMMM dd, yyyy h:mm:ss a').format(scannedDate)}',
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                ],
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


Widget detectLogins(BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('logintime')
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
            bool seen = doc['seen'] ?? false; // Default to false if 'seen' is not set
            Timestamp scannedTime = doc['scannedTime'];
            DateTime loginDate = scannedTime.toDate();
            Color textColor = seen ? Colors.grey.shade400 : Colors.white; // Set color based on 'seen'

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.login,
                        color: textColor,
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'USER LOGGED IN:',
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
                    'Login Time: ${DateFormat('MMMM dd, yyyy h:mm:ss a').format(loginDate)}',
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'User ID: ${doc['userID']}',
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                  SizedBox(height: 4.0),
                ],
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
        .collection('logouttime')
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
            bool seen = doc['seen'] ?? false; // Default to false if 'seen' is not set
            Timestamp scannedTime = doc['scannedTime'];
            DateTime logoutDate = scannedTime.toDate();
            Color textColor = seen ? Colors.grey.shade400 : Colors.white; // Set color based on 'seen'

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: textColor,
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'USER LOGGED OUT:',
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
                    'Logout Time: ${DateFormat('MMMM dd, yyyy h:mm:ss a').format(logoutDate)}',
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'User ID: ${doc['userID']}',
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                  SizedBox(height: 4.0),
                ],
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


class HistoryPageAdmin extends StatefulWidget {
  HistoryPageAdmin({Key? key}) : super(key: key);

  @override
  State<HistoryPageAdmin> createState() => _HistoryPageAdminState();
}

class _HistoryPageAdminState extends State<HistoryPageAdmin> {
  String selectedFilter = 'All';

  bool hasData(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.hasData && snapshot.data!.docs.isNotEmpty;
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
            return Center(child: Text('No new user found.'));
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No cash-in logs found.'));
          }
          return cashInsWidget;
        },
      );
    } else if (selectedFilter == 'Logins') {
      Widget loginsWidget = detectLogins(context);
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logintime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No login records found.'));
          }
          return loginsWidget;
        },
      );
    } else if (selectedFilter == 'Logouts') {
      Widget logoutsWidget = detectLogouts(context);
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logouttime')
            .where('loggedIn', isEqualTo: 'false')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No logout records found.'));
          }
          return logoutsWidget;
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
                  image: AssetImage('assets/images/bg.png'),
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
                        color: Colors.green[800],
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.history,
                                    color: Colors.lightGreen,
                                  ),
                                  const SizedBox(width: 8.0),
                                  const Text(
                                    'HISTORY',
                                    style: TextStyle(color: Colors.white, fontSize: 20),
                                  ),
                                ],
                              ),
                              // Dropdown button for filter
                              DropdownButton<String>(
                                value: selectedFilter,
                                icon: Icon(
                                  Icons.filter_alt,
                                  color: Colors.lightGreen,
                                ),
                                onChanged: (String? newFilter) {
                                  if (newFilter != null) {
                                    setState(() {
                                      selectedFilter = newFilter;
                                    });
                                  }
                                },
                                style: TextStyle(color: Colors.white), // White text when dropdown is closed
                                dropdownColor: Colors.green[800], // Background color of the dropdown
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
