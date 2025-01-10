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
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
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
                        color: isDarkMode ? Colors.white : Colors.green[800],
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
                                  builder: (context) => ProfilePage(),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.black87
                                    : Colors.green[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth.instance.currentUser!.uid) // Fetch the logged-in user's document
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }
                                      if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      }
                                      if (snapshot.hasData) {
                                        // Retrieve the document data as a Map
                                        Map<String, dynamic>? _userData = snapshot.data!.data() as Map<String, dynamic>?;

                                        // Debug log for the user data
                                        print('User document data: $_userData');

                                        // Retrieve profileIconIndex or use default and add +1
                                        int profileIconIndex = _userData != null && _userData['profileIconIndex'] != null
                                            ? (_userData['profileIconIndex'] as int) + 1
                                            : 1; // Default to 1 if profileIconIndex is null or missing

                                        // Debug log for the profileIconIndex
                                        print('Updated profileIconIndex (with +1): $profileIconIndex');

                                        return CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Colors.grey[200], // Fallback background color
                                          backgroundImage: _userData != null &&
                                              _userData['profileImage'] != null &&
                                              _userData['profileImage'].isNotEmpty
                                              ? NetworkImage(_userData['profileImage']) // Display the uploaded image
                                              : AssetImage('assets/images/Icon$profileIconIndex.png') as ImageProvider, // Display the selected icon
                                          child: _userData != null &&
                                              _userData['profileImage'] != null &&
                                              _userData['profileImage'].isNotEmpty
                                              ? null // Do not display a child if the profile image is available
                                              : null, // No child if profileImage is null (AssetImage used instead)
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
                                              fontSize: 30, fontWeight: FontWeight.bold),
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
                                              fontSize: 17, fontWeight: FontWeight.bold),
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
                        color: isDarkMode
                            ? Colors.white
                            : Colors.green.shade800,
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
                          color: isDarkMode
                              ? Colors.black87
                              : Colors.green.shade100.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              "User QR Code",
                              style: TextStyle(
                                fontSize: 24,
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_qrData != null)
                              QrImageView(
                                data: _qrData!,
                                version: QrVersions.auto,
                                size: 325.0,
                                foregroundColor: isDarkMode ? Colors.white : Colors.black,
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
          // Title at the top
          Positioned(
            top: 80, // Adjust the top position as needed
            left: 0, // Start from the left edge of the screen
            right: 0, // Make it span to the right edge as well
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
              children: [
                Icon(
                  Icons.attach_money,
                  size: 24, // Adjust the icon size as needed
                  color: isDarkMode ? Colors.white : Colors.green,
                ),
                const SizedBox(width: 8), // Adds space between the icon and text
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
            top: 60, // Adjust this value to move the button down
            left: 16, // Horizontal position
            child: FloatingActionButton(
              mini: true, // Smaller back button
              backgroundColor: isDarkMode ? Colors.grey : Colors.green,
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
