import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'users_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

      // If there are new users
      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
        return Column(
          children: snapshot.data!.docs.map((doc) {
            Timestamp registerTime = doc['registerTime'];
            DateTime registerDate = registerTime.toDate();

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
                    'Scanned Time: ${DateFormat('MMMM dd, yyyy h:mm:ss a').format(scannedDate)}',
                    style: TextStyle(color: Colors.black, fontSize: 14),
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
        .where('seen', isEqualTo: false)
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
            DateTime loginDate = scannedTime.toDate();

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
                        color: Colors.white,
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'USER LOGGED IN:',
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
                    'Login Time: ${DateFormat('MMMM dd, yyyy h:mm:ss a').format(loginDate)}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'User ID: ${doc['userID']}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
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
        .where('seen', isEqualTo: false)
        .where('loggedIn', isEqualTo: 'false')
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
            DateTime logoutDate = scannedTime.toDate();

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
                        color: Colors.white,
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'USER LOGGED OUT:',
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
                    'Logout Time: ${DateFormat('MMMM dd, yyyy h:mm:ss a').format(logoutDate)}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'User ID: ${doc['userID']}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
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

class AlertsPageAdmin extends StatefulWidget {
  AlertsPageAdmin({Key? key}) : super(key: key);

  @override
  State<AlertsPageAdmin> createState() => _AlertsPageAdminState();
}

class _AlertsPageAdminState extends State<AlertsPageAdmin> {
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
      Widget loginsWidget = detectLogins(context);
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logintime')
            .where('seen', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No login records found.', style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          return loginsWidget;
        },
      );
    } else if (selectedFilter == 'Logouts') {
      Widget logoutsWidget = detectLogouts(context);
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logouttime')
            .where('seen', isEqualTo: false)
            .where('loggedIn', isEqualTo: 'false')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No logout records found.', style: TextStyle(color: Colors.white, fontSize: 18)));
          }
          return logoutsWidget;
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
                .where('adminID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, cashinsSnapshot) {
              if (cashinsSnapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              return StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('logintime')
                    .where('seen', isEqualTo: false)
                    .snapshots(),
                builder: (context, loginsSnapshot) {
                  if (loginsSnapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('logouttime')
                        .where('seen', isEqualTo: false)
                        .where('loggedIn', isEqualTo: 'false')
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
                                    Icons.notifications,
                                    color: Colors.lightGreen,
                                  ),
                                  const SizedBox(width: 8.0),
                                  const Text(
                                    'ALERTS',
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
                          const SizedBox(height: 30.0),
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
