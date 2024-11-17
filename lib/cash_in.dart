import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? _qrData;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _fetchUserData();
      _generateQRCode();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      // Fetch user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)  // Fetching the current user's document
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc;
          _qrData = _userData?.get('userID')?.toString() ?? 'Not available'; // Retrieve the numeric userID
        });
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _generateQRCode() {
    if (_user != null) {
      setState(() {
        _qrData = _user!.uid; // QR code data is now only the user's ID
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                                        .doc(_user!.uid)
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 16.0),
                    Container(
                      padding: const EdgeInsets.all(20.0),
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
                      child: Container(
                      decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            "User QR Code",
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_qrData != null)
                            QrImageView(
                              data: _qrData!,
                              version: QrVersions.auto,
                              size: 325.0,
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.green,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
