import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart';  // Firebase Firestore
import 'login.dart';
import 'dart:io';
import 'create_qr.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

class ScanPage extends StatefulWidget {
  @override
  _QRScannerState createState() => _QRScannerState();
}

class _QRScannerState extends State<ScanPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  String _result = '';
  bool _hasLoggedIn = false;
  Timer? _debounce;
  DateTime? _lastScanTime;
  late WebViewController _webViewController; // Define WebViewController for WebView widget
  User? currentUser = FirebaseAuth.instance.currentUser;
  Timer? _resetTimer; // Timer for resetting the QR scanner text

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _controller?.pauseCamera();
    }
    _controller?.resumeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _debounce?.cancel();
    _resetTimer?.cancel(); // Dispose of the reset timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 4,
                child: QRView(
                  key: _qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.red,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 300,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity, // Ensures the container takes the full width
                  height: double.infinity, // Ensures the container takes the full height
                  color: isDarkMode
                      ? Colors.white
                      : Colors.green[700], // Dynamic background color
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _result.isEmpty
                            ? 'Scan a QR code'
                            : 'Scanned Successfully',
                        style: TextStyle(
                          fontSize: 20,
                          color: isDarkMode
                              ? Colors.black
                              : Colors.white, // Dynamic text color
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 40, // Adjust as necessary for your layout
            left: 20, // Adjust the alignment from the left
            child: FloatingActionButton(
              mini: true, // Smaller back button
              backgroundColor: isDarkMode ? Colors.grey : Colors.green,
              onPressed: () {
                Navigator.pop(context); // Navigate back to the previous screen
              },
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToSignOut() {
    // Sign out logic (e.g., FirebaseAuth sign-out)
    FirebaseAuth.instance.signOut();

    // Navigate to login or home page
    Navigator.pushReplacementNamed(context, '/login'); // or wherever you want to navigate
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      final code = scanData.code!;
      setState(() {
        _result = code;
      });

      // Cancel any previous debounce timers
      _debounce?.cancel();

      // Pause the camera
      _controller?.pauseCamera();

      _debounce = Timer(Duration(seconds: 1), () async {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No user logged in"),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );

          // Resume the camera after showing the snackbar
          _controller?.resumeCamera();
          return;
        }

        // Get user data from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("User document not found"),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );

          // Resume the camera after showing the snackbar
          _controller?.resumeCamera();
          return;
        }

        String firstName = userDoc['firstName'] ?? 'Unknown';
        String lastName = userDoc['lastName'] ?? 'Unknown';
        String userType = userDoc['userType'] ?? 'User';

        // Handle different F code cases
        if (code == "https://youtu.be/92P2aD0f8IU?si=VwUvTRzh8ayDXUPN" ||
            code == "https://youtu.be/a8aRY6e-oyI?si=-wTlkemy0DRhldsI" ||
            code == "https://youtu.be/uXKo6MHQ9WM?si=pyk4ayf9CmaYRrHU" ||
            code == "https://youtu.be/9ZQYw1Ysqvg?si=lN2_2UV1scXcX4AG" ||
            code == "https://youtu.be/gPx6ePgVFss?si=3Cj5GaYeYZkkQfU8") {
          await _launchURL(code);
          // Resume the camera after handling the URL
          _controller?.resumeCamera();
          return;
        }

        if (code.contains("http://www.FitTrack_Login.com")) {
          _handleLogin(user, firstName, lastName);
        } else if (code.contains("http://www.FitTrack_Logout.com")) {
          _handleLogout(user);
        } else {
          _handleAmountAddition(code, user, userType);
        }

        // Resume the camera after handling the QR code
        _controller?.resumeCamera();
      });
    });
  }

// Handle login logic
  Future<void> _handleLogin(User user, String firstName, String lastName) async {
    // First, get the actual 'userID' from the 'users' collection using the Firebase UID
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid) // Using Firebase UID to get the user's document
        .get();

    if (!userDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User not found in 'users' collection."),
          behavior: SnackBarBehavior.floating, // Floating snackbar
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    String actualUserID = userDoc['userID'];

    QuerySnapshot loginRecord = await FirebaseFirestore.instance
        .collection('logintime')
        .where('userID', isEqualTo: actualUserID)
        .orderBy('scannedTime', descending: true)
        .limit(1)
        .get();

    if (loginRecord.docs.isNotEmpty) {
      DocumentSnapshot lastRecord = loginRecord.docs.first;
      bool loggedOut = lastRecord['loggedOut'] ?? true;

      if (!loggedOut) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You are already logged in!"),
            behavior: SnackBarBehavior.floating, // Floating snackbar
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Check user's wallet balance before allowing login
        await _processLogin(user, actualUserID, firstName, lastName);
      }
    } else {
      // No previous login record found; proceed to check wallet balance and login
      await _processLogin(user, actualUserID, firstName, lastName);
    }
  }

  Future<void> _processLogin(
      User user, String actualUserID, String firstName, String lastName) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users') // Collection is 'users'
        .doc(user.uid) // Use user ID to get their document
        .get();

    if (userDoc.exists) {
      // Get and handle the wallet balance
      double walletBalance = (userDoc['wallet'] is int)
          ? (userDoc['wallet'] as int).toDouble()
          : userDoc['wallet'] ?? 0.0;

      // Check if the balance is enough for the login (before and after deduction)
      if (walletBalance >= 30.0) {
        // Subtract 30 from the wallet balance
        double newBalance = walletBalance - 30;

        // Update the wallet balance in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'wallet': newBalance});

        // Log the user in
        await _logUserLogin(firstName, lastName);

        // Update the 'loggedOut' field to false in the last login record
        QuerySnapshot loginRecord = await FirebaseFirestore.instance
            .collection('logintime')
            .where('userID', isEqualTo: actualUserID)
            .orderBy('scannedTime', descending: true)
            .limit(1)
            .get();

        if (loginRecord.docs.isNotEmpty) {
          await loginRecord.docs.first.reference.update({'loggedOut': false});
        } else {
          // If no record exists, create a new one
          await FirebaseFirestore.instance.collection('logintime').add({
            'userID': actualUserID,
            'firstName': firstName,
            'lastName': lastName,
            'scannedTime': Timestamp.now(),
            'loggedOut': false, // Set to false for the new login
          });
        }
      } else {
        // If the user doesn't have enough balance, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Insufficient balance. Please add funds to your wallet."),
            behavior: SnackBarBehavior.floating, // Floating snackbar
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Handle case where the user document doesn't exist in the 'users' collection
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User not found."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


// Handle logout logic
  Future<void> _handleLogout(User user) async {
    try {
      // First, get the actual 'userID' from the 'users' collection using the Firebase UID
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)  // Using Firebase UID to get the user's document
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not found in 'users' collection."),
            behavior: SnackBarBehavior.floating, // Floating snackbar
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Get the actual userID from the 'users' collection
      String actualUserID = userDoc['userID'];  // Assuming 'userID' is stored in the 'users' collection

      // Now, search for the most recent login record in the 'logintime' collection for that userID
      QuerySnapshot loginRecord = await FirebaseFirestore.instance
          .collection('logintime')
          .where('userID', isEqualTo: actualUserID)  // Use actualUserID for the query
          .orderBy('scannedTime', descending: true)  // Order by latest login time
          .limit(1)
          .get();

      if (loginRecord.docs.isEmpty) {
        // No login records found, inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No login records found for this user."),
            behavior: SnackBarBehavior.floating, // Floating snackbar
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Get the most recent login document
      DocumentSnapshot lastRecord = loginRecord.docs.first;
      bool loggedOut = lastRecord['loggedOut'] ?? false; // Check if the user is already logged out

      if (loggedOut) {
        // If already logged out, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You are already logged out!"),
            behavior: SnackBarBehavior.floating, // Floating snackbar
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // If not logged out, log the user out
        await _logUserLogout(lastRecord.id); // Pass the recordID to the logout function
      }
    } catch (e) {
      // Handle errors (e.g., Firestore read failure)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error handling logout: $e"),
          behavior: SnackBarBehavior.floating, // Floating snackbar
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  Future<void> _logUserLogout(String recordID) async {
    try {
      // Reference to the current authenticated user
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // Handle case where there is no authenticated user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User is not authenticated."),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Reference to the user's document in the 'users' collection using the Firebase UID
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      DocumentSnapshot userSnapshot = await userDocRef.get();

      if (!userSnapshot.exists) {
        // Handle case where the user document doesn't exist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User data not found."),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Get the 'userID', 'firstName', and 'lastName' from the 'users' collection
      String actualUserID = userSnapshot['userID'] ?? ''; // Assuming 'userID' is the field
      String firstName = userSnapshot['firstName'] ?? '';  // Assuming 'firstName' field exists
      String lastName = userSnapshot['lastName'] ?? '';    // Assuming 'lastName' field exists

      // Reference to the login document in the 'logintime' collection using the actual userID
      DocumentReference loginDocRef = FirebaseFirestore.instance.collection('logintime').doc(recordID);

      // Check if the document exists in the 'logintime' collection
      DocumentSnapshot loginSnapshot = await loginDocRef.get();

      if (loginSnapshot.exists) {

        String getDayName(int weekday) {
          switch (weekday) {
            case 1: return 'monday';
            case 2: return 'tuesday';
            case 3: return 'wednesday';
            case 4: return 'thursday';
            case 5: return 'friday';
            case 6: return 'saturday';
            case 7: return 'sunday';
            default: return '';
          }
        }

        // Create a new entry in the 'loghistory' collection
        await FirebaseFirestore.instance.collection('loghistory').add({
          'firstName': firstName,
          'lastName': lastName,
          'scannedQR': "http://www.FitTrack_Logout.com",
          'scannedTime': FieldValue.serverTimestamp(),
          'seen': false,
          'type': "logout",
          'day': getDayName(DateTime.now().weekday),
          'userID': actualUserID,
        });
        // If the document exists, update the 'loggedOut' field in the 'logintime' collection
        await loginDocRef.update({
          'loggedOut': true,  // Setting loggedOut to true (user has logged out)
          'scannedTime': FieldValue.serverTimestamp(), // Automatically set to the current server time
        });

        // Create a new entry in the 'logouttime' collection
        await FirebaseFirestore.instance.collection('logouttime').doc(actualUserID).set({
          'firstName': firstName,
          'lastName': lastName,
          'loggedIn': 'false',  // LoggedIn is set to 'false' in the 'logouttime' collection
          'scannedQR': "http://www.FitTrack_Logout.com",  // QR code URL indicating logout
          'scannedTime': FieldValue.serverTimestamp(), // Automatically set to the current server time
          'userID': actualUserID,  // Include the actual userID
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout recorded successfully"),
            behavior: SnackBarBehavior.floating, // Floating snackbar
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Handle case where the document does not exist in the 'logintime' collection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No login record found for this user."),
            behavior: SnackBarBehavior.floating, // Floating snackbar
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Call the method to proceed with sign-out
      _proceedToSignOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error logging out: $e"),
          behavior: SnackBarBehavior.floating, // Floating snackbar
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  Future<void> _handleAmountAddition(String code, User user, String userType) async {
    // First check if the current user is an admin
    if (userType != 'Admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Only administrators can add amounts to wallets."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return; // Exit the function early if not an admin
    }

    final regex = RegExp(r'^(20[2-9]\d{2}\d+)$'); // Regex to match valid userID (2020+)
    final match = regex.firstMatch(code);

    if (match != null && match.groupCount == 1) {
      String scannedUserID = match.group(1)!; // Group 1 for userID

      // Prompt the admin to enter the amount to cash in
      TextEditingController amountController = TextEditingController();
      bool? isAmountConfirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Enter Cash-in Amount"),
            content: TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: "Amount",
                hintText: "Enter amount to cash in",
              ),
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text("Confirm"),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (isAmountConfirmed == true && amountController.text.isNotEmpty) {
        String amount = amountController.text.trim();

        // Show confirmation dialog for the entered amount
        bool? isFinalConfirmation = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm Amount"),
              content: Text("Are you sure you want to add $amount to user ID: $scannedUserID's wallet?"),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text("Yes"),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );

        if (isFinalConfirmation == true) {
          // Logic to add the amount to the user's wallet
          await _addAmountToWallet(scannedUserID, amount);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Added $amount to user ID: $scannedUserID's wallet."),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invalid amount entered. Please try again."),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Scanned unknown QR code: $code"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri _url = Uri.parse(url);

    if (await canLaunchUrl(_url)) {
      await launchUrl(
        _url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      // In-app WebView fallback using WebViewController
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Optionally handle progress updates here
            },
            onPageStarted: (String url) {},
            onPageFinished: (String url) {},
            onHttpError: (HttpResponseError error) {},
            onWebResourceError: (WebResourceError error) {},
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith('https://youtu.be/92P2aD0f8IU?si=VwUvTRzh8ayDXUPN')) {
                return NavigationDecision.prevent;
              } else if (request.url.startsWith('https://youtu.be/a8aRY6e-oyI?si=-wTlkemy0DRhldsI')) {
                return NavigationDecision.prevent;
              } else if (request.url.startsWith('https://youtu.be/uXKo6MHQ9WM?si=pyk4ayf9CmaYRrHU')) {
                return NavigationDecision.prevent;
              } else if (request.url.startsWith('https://youtu.be/9ZQYw1Ysqvg?si=lN2_2UV1scXcX4AG')) {
                return NavigationDecision.prevent;
              } else if (request.url.startsWith('https://youtu.be/gPx6ePgVFss?si=3Cj5GaYeYZkkQfU8')) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(url));

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text("FitTrack WebViewer")),
            body: WebViewWidget(controller: controller),
          ),
        ),
      );
    }
  }

  // Function to find the user document by userID and add amount to wallet in Firestore
  Future<void> _addAmountToWallet(String scannedUserID, String amount) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("No user is logged in.");
      return;
    }

    // Query to find the user document with the specified userID
    QuerySnapshot scannedUserQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('userID', isEqualTo: scannedUserID) // Searching by field 'userID'
        .get();

    // Check if any documents were found
    if (scannedUserQuery.docs.isNotEmpty) {
      // Get the first matching document
      DocumentSnapshot scannedUserDoc = scannedUserQuery.docs.first;
      String documentID = scannedUserDoc.id; // Get the document ID

      // Admin (the person performing the scan and confirmation)
      String adminID = currentUser.uid; // Use the current user's uid as adminID

      // Fetch the current user's name from the users collection (if not null)
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminID)
          .get();

      String adminName = '';
      if (adminDoc.exists) {
        adminName = '${adminDoc['firstName']} ${adminDoc['lastName']}'; // Admin's full name
      }

      String userName = '${scannedUserDoc['firstName']} ${scannedUserDoc['lastName']}'; // User's name

      try {
        // Ensure the amount is a valid integer
        int amountToAdd = int.parse(amount);

        // Update the wallet field in the found user's document
        await FirebaseFirestore.instance.collection('users').doc(documentID).update({
          'wallet': FieldValue.increment(amountToAdd), // Increment the wallet amount
        });

        print("Successfully added $amount to user ID: $scannedUserID's wallet.");

        // Log the cash-in transaction in the cashinlogs collection
        await FirebaseFirestore.instance.collection('cashinlogs').add({
          'adminID': adminID, // Use the current user's uid as adminID
          'adminName': adminName, // Use the fetched admin name
          'amount': amountToAdd,
          'userID': scannedUserID,
          'userName': userName,
          'scannedTime': FieldValue.serverTimestamp(), // Automatically add timestamp
          'seen' : false,
        });

        print("Cash-in transaction logged successfully for user ID: $scannedUserID.");
      } catch (e) {
        print('Error updating wallet: $e');
        throw e; // Rethrow to handle in the calling method
      }
    } else {
      throw Exception('User document does not exist for userID: $scannedUserID');
    }
  }

  Future<void> _logUserLogin(String firstName, String lastName) async {
    // Get the current FirebaseAuth user
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle case where there is no authenticated user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User is not authenticated."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Reference to the user's document in the 'users' collection
    DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    // Fetch the user's document to get the 'userID'
    DocumentSnapshot userSnapshot = await userDocRef.get();

    if (!userSnapshot.exists) {
      // Handle case where the user document doesn't exist
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User data not found."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Get the 'userID' (assuming 'userID' is the field in the 'users' collection)
    String actualUserID = userSnapshot['userID'] ?? ''; // Assuming the field is 'userID'

    // Reference to the login document for the given userID
    DocumentReference loginDocRef = FirebaseFirestore.instance
        .collection('logouttime')
        .doc(actualUserID); // Directly use currentUser.uid as document ID

    // Check if a document already exists for the given userID
    DocumentSnapshot loginSnapshot = await loginDocRef.get();

    if (loginSnapshot.exists) {
      await loginDocRef.update({
        'loggedIn': true,
        'scannedTime': FieldValue.serverTimestamp() ?? Timestamp.now(), // Fallback if serverTimestamp() is null
      });

      await FirebaseFirestore.instance.collection('loghistory').add({
        'firstName': firstName,
        'lastName': lastName,
        'scannedQR': "http://www.FitTrack_Login.com",
        'scannedTime': FieldValue.serverTimestamp() ?? Timestamp.now(), // Fallback if serverTimestamp() is null
        'seen': false,
        'type': "login",
        'day': getDayName(DateTime.now().weekday),
        'userID': actualUserID,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Welcome back! You've successfully logged in."),
          behavior: SnackBarBehavior.floating, // Floating snackbar
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // If no document exists for the user, create a new login record
      DocumentReference loginDocRef = FirebaseFirestore.instance
          .collection('logintime')
          .doc(actualUserID); // Use actualUserID as the document ID

      await loginDocRef.set({
        'firstName': firstName,
        'lastName': lastName,
        'loggedOut': false,
        'scannedQR': "http://www.FitTrack_Login.com",
        'scannedTime': FieldValue.serverTimestamp(), // Automatically set to the current server time
        'userID': actualUserID, // Store the actual userID from the 'users' collection
      });

      // Add entry to the 'loghistory' collection
      await FirebaseFirestore.instance.collection('loghistory').add({
        'firstName': firstName,
        'lastName': lastName,
        'scannedQR': "http://www.FitTrack_Login.com",
        'scannedTime': FieldValue.serverTimestamp(),
        'seen': false,
        'type': "login",
        'day': getDayName(DateTime.now().weekday),
        'userID': actualUserID,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You have successfully logged in."),
          behavior: SnackBarBehavior.floating, // Floating snackbar
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return '';
    }
  }

}