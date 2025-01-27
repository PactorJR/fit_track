import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

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
  bool _isLoading = true;
  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    _fetchUserData();
    _generateQRCode();
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

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc;
          _qrData = _userData?.get('userID')?.toString() ??
              'Not available';
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
        _qrData = _user!.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double containerHeight;
    double containerWidth;
    double QRcontainerHeight;

    if (screenWidth <= 409) {
      containerHeight = screenHeight * 0.23;
      QRcontainerHeight = screenHeight * 0.38;
      containerWidth = screenWidth * 0.90;
    } else if (screenWidth >= 410) {
      QRcontainerHeight = screenHeight * 0.35;
      containerHeight = screenHeight * 0.22;
      containerWidth = screenWidth * 0.90;
    } else {
      containerHeight = screenHeight * 0.25;
      containerWidth = screenWidth * 0.90;
      QRcontainerHeight = screenHeight * 0.23;
    }

    return Scaffold(
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
          Padding(
            padding: const EdgeInsets.only(top: 150.0),
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      Container(
                      height: containerHeight,
                      width: containerWidth,
                      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black : Colors.green.shade800.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ProfilePage()),
                                );
                              },
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [

                                    StreamBuilder<DocumentSnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(FirebaseAuth.instance.currentUser!.uid)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        }
                                        if (snapshot.hasError) {
                                          return Text('Error: ${snapshot.error}');
                                        }
                                        if (snapshot.hasData) {
                                          Map<String, dynamic>? _userData =
                                          snapshot.data!.data() as Map<String, dynamic>?;
                                          int profileIconIndex = _userData != null &&
                                              _userData['profileIconIndex'] != null
                                              ? (_userData['profileIconIndex'] as int) + 1
                                              : 1;

                                          double avatarRadius =
                                          screenWidth <= 409 ? 30.0 : screenWidth <= 410 ? 40.0 : 50.0;

                                          return CircleAvatar(
                                            radius: avatarRadius,
                                            backgroundColor: Colors.grey[200],
                                            backgroundImage: _userData != null &&
                                                _userData['profileImage'] != null &&
                                                _userData['profileImage'].isNotEmpty
                                                ? NetworkImage(_userData['profileImage'])
                                                : AssetImage('assets/images/Icon$profileIconIndex.png')
                                            as ImageProvider,
                                          );
                                        }
                                        return Text('No user data found.');
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${_userData?.get('firstName') ?? 'First Name'} ${_userData?.get('lastName') ?? 'Last Name'}",
                                          style: TextStyle(
                                            fontSize: screenWidth <= 409 ? 24 : 30,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "User ID: ${_userData?.get('userID') ?? 'Not available'}",
                                          style: TextStyle(fontSize: screenWidth <= 409 ? 13 : 17, color: Colors.white,),
                                        ),
                                        Text(
                                          "User Type: ${_userData?.get('userType') ?? 'Not available'}",
                                          style: TextStyle(fontSize: screenWidth <= 409 ? 13 : 17, color: Colors.white,),
                                        ),
                                        Text(
                                          "Wallet: ₱ ${_userData?.get('wallet') ?? 'Not available'}",
                                          style: TextStyle(
                                            fontSize: screenWidth <= 409 ? 13 : 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "Status: ",
                                              style: TextStyle(
                                                fontSize: screenWidth <= 409 ? 13 : 17,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              _userData?.get('loggedStatus') == false
                                                  ? 'Logged Out'
                                                  : 'Inside',
                                              style: TextStyle(
                                                fontSize: screenWidth <= 409 ? 13 : 17,
                                                fontWeight: FontWeight.bold,
                                                color: _userData?.get('loggedStatus') == false
                                                    ? Colors.red
                                                    : Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                        const SizedBox(height: 50.0),
                        Container(
                          width: 390,
                          height: QRcontainerHeight,
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.black : Colors.green
                                .shade800.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                            child: Column(
                              children: [
                                Text(
                                  "User QR Code",
                                  style: TextStyle(
                                    fontSize: screenWidth <= 409 ? 20 : 25,
                                    color: isDarkMode ? Colors.white : Colors
                                        .white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_qrData != null)
                                  QrImageView(
                                    data: _qrData!,
                                    version: QrVersions.auto,
                                    size: screenWidth <= 409 ? 200 : 235,
                                    foregroundColor: isDarkMode
                                        ? Colors.white
                                        : Colors.white,
                                  ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: MediaQuery
                .of(context)
                .size
                .width / 2 - 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.attach_money,
                  size: 24,
                  color: isDarkMode ? Colors.white : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cash In',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            left: 16,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: FloatingActionButton(
                mini: true,
                backgroundColor: isDarkMode ? Colors.grey : Colors.green,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
