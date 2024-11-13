import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Use QrImage
import 'package:intl/intl.dart'; // For date and time formatting
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Firestore
import 'profile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cash-In',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CashInPage(),
    );
  }
}

class CashInPage extends StatefulWidget {
  @override
  _CashInPageState createState() => _CashInPageState();
}

class _CashInPageState extends State<CashInPage> {
  User? _user;
  DocumentSnapshot? _userData;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc;
        });
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'), // Background image
                fit: BoxFit.cover, // Cover the entire container
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // New container on top
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20.0, horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: Colors.green.shade800.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ProfilePage()),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(_user!.uid) // Use the actual user ID
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }
                                      if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      }
                                      if (snapshot.hasData) {
                                        var userData = snapshot.data;
                                        return CircleAvatar(
                                          radius: 40,
                                          backgroundImage: userData != null && userData.data() != null
                                              ? AssetImage(
                                            'assets/images/Icon${(userData.get('profileIconIndex') ?? 1) + 1}.png',
                                          )
                                              : AssetImage('assets/images/Icon1.png'),
                                        );
                                      }
                                      return Text('No user data found.');
                                    },
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${_userData?.get('firstName') ?? 'First Name'} ${_userData?.get('lastName') ?? 'Last Name'}",
                                          style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "User ID: ${_userData?.get('userID') ?? 'Not available'}",
                                          style: TextStyle(fontSize: 17),
                                        ),
                                        Text(
                                          "User Type: ${_userData?.get('userType') ?? 'Not available'}",
                                          style: TextStyle(fontSize: 17),
                                        ),
                                        Text(
                                          "Wallet: ₱ ${_userData?.get('wallet') ?? 'Not available'}",
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold),
                                        ),
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
                    const SizedBox(height: 16.0), // Spacing

                    // Existing container
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _studentIdController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Student ID',
                              labelStyle: const TextStyle(color: Colors.white),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            controller: _amountController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              labelStyle: const TextStyle(color: Colors.white),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24.0),
                          ElevatedButton(
                            onPressed: () {
                              String studentId = _studentIdController.text;
                              String amount = _amountController.text;
                              String currentDateTime = DateFormat('yyyy-MM-dd_HH:mm:ss').format(DateTime.now());

                              // Construct the QR code data
                              String qrData = '${studentId}_${amount}_$currentDateTime';

                              print("QR Data: $qrData"); // Debug print

                              // Show the QR code in a dialog
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    content: SizedBox(
                                      width: 400.0, // Set width to ensure dialog has enough space
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          QrImageView(
                                            data: qrData,
                                            version: QrVersions.auto,
                                            size: 300.0,
                                          ),
                                          const SizedBox(height: 0),
                                          Text('Cash-in Amount: ₱$amount'),
                                          Text('Cash-in to UserID: $studentId'),
                                          Text('Cash-in Date & Time: $currentDateTime'),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Close'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 60, // Adjust this value to move the button down
            left: 16, // Horizontal position
            child: FloatingActionButton(
              mini: true, // Smaller back button
              backgroundColor: Colors.green,
              onPressed: () {
                Navigator.of(context).pop(); // Navigate back to the previous screen
              },
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
