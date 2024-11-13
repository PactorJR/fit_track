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
  late WebViewController _webViewController;  // Define WebViewController for WebView widget

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _controller?.pauseCamera();
    }
    _controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _result.isEmpty
                          ? 'Scan a QR code'
                          : 'Scanned Successfully, Remove the focus of Camera from QR to Proceed',
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 40, // Adjust as necessary for your layout
            left: 20, // Adjust the alignment from the left
            child: FloatingActionButton(
              mini: true, // Smaller back button
              backgroundColor: Colors.green,
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


  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      final code = scanData.code!;
      setState(() {
        _result = code;
      });

      _debounce?.cancel();
      _debounce = Timer(Duration(seconds: 1), () async {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No user logged in")),
          );
          return;
        }

        if (code == "https://youtu.be/yWnacRo2VbA?si=S8JUbMKu-0lAFctJ") {
          // Launch the YouTube video URL
          await _launchURL(code);
          return;
        } else if (code == "https://youtu.be/JyV7mUFSpXs?si=p5-V_q6kyIqBrIbD"){
          await _launchURL(code);
          return;
        } else if (code == "https://youtu.be/Swu1pxRJ4m4?si=M5THkeRSfAVBSr6s"){
          await _launchURL(code);
          return;
        } else if (code == "https://youtu.be/eGo4IYlbE5g?si=lR9e2JfjwZyXOGOd"){
          await _launchURL(code);
          return;
        }

        // Get user data from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("User document not found")),
          );
          return;
        }

        String firstName = userDoc['firstName'] ?? 'Unknown';
        String lastName = userDoc['lastName'] ?? 'Unknown';
        String userType = userDoc['userType'] ?? 'User'; // Get userType

        // Check if the scanned code is for login
        if (code.contains("http://www.FitTrack_Login.com")) {
          // Check if the user is already logged in
          QuerySnapshot loginRecord = await FirebaseFirestore.instance
              .collection('logintime')
              .where('userID', isEqualTo: user.uid)
              .orderBy('scannedTime', descending: true)
              .limit(1)
              .get();

          if (loginRecord.docs.isNotEmpty) {
            DocumentSnapshot lastRecord = loginRecord.docs.first;
            bool loggedOut = lastRecord['loggedOut'] ?? true;

            if (!loggedOut) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("You are already logged in!")),
              );
            } else {
              // Log the user in if they are logged out
              await _logUserLogin(user.uid, firstName, lastName);
            }
          } else {
            // No previous login record found; log the user in
            await _logUserLogin(user.uid, firstName, lastName);
          }
        } else if (code.contains("http://www.FitTrack_Logout.com")) {
          // Check the most recent login record for logout logic
          QuerySnapshot loginRecord = await FirebaseFirestore.instance
              .collection('logintime')
              .where('userID', isEqualTo: user.uid)
              .orderBy('scannedTime', descending: true)
              .limit(1)
              .get();

          if (loginRecord.docs.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("No login records found")),
            );
            return;
          }

          DocumentSnapshot lastRecord = loginRecord.docs.first;
          bool loggedOut = lastRecord['loggedOut'] ?? true;

          if (loggedOut) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("You are already logged out!")),
            );
          } else {
            await _logUserLogout(lastRecord.id);
          }
        } else {
          // New feature: Check for user ID and wallet amount
          final regex = RegExp(r'^(\w+)_(\d+)_(.+)$'); // Adjust regex to match your pattern
          final match = regex.firstMatch(code);

          if (match != null && match.groupCount == 3) {
            String scannedUserID = match.group(1)!; // Group 1 for userID
            String amount = match.group(2)!;         // Group 2 for amount
            String dateTime = match.group(3)!;       // Group 3 for date and time

            // Debug print statements
            print("Scanned User ID: $scannedUserID");
            print("Amount: $amount");
            print("Date Time: $dateTime");

            // Check if the scanned userID exists in Firestore using a query
            QuerySnapshot scannedUserQuery = await FirebaseFirestore.instance
                .collection('users')
                .where('userID', isEqualTo: scannedUserID) // Assuming 'userID' is the field name
                .get();

            if (scannedUserQuery.docs.isNotEmpty) {
              DocumentSnapshot scannedUserDoc = scannedUserQuery.docs.first;

              // Check if the current user is an admin
              if (userType == 'Admin') {
                // Show a confirmation dialog
                bool? isConfirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Confirm Amount"),
                      content: Text("Have you received the exact amount of $amount for user ID: $scannedUserID?"),
                      actions: [
                        TextButton(
                          child: Text("No"),
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

                if (isConfirmed == true) {
                  // Logic to add the amount to the user's wallet
                  await _addAmountToWallet(scannedUserID, amount);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Added $amount to user ID: $scannedUserID's wallet.")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("You do not have permission to add money.")),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Scanned user ID does not exist.")),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Scanned unknown QR code: $_result")),
            );
          }
        }
      });
    });
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
              if (request.url.startsWith('https://youtu.be/yWnacRo2VbA?si=S8JUbMKu-0lAFctJ')) {
                return NavigationDecision.prevent;
              } else if (request.url.startsWith('https://youtu.be/JyV7mUFSpXs?si=p5-V_q6kyIqBrIbD')) {
                return NavigationDecision.prevent;
              } else if (request.url.startsWith('https://youtu.be/Swu1pxRJ4m4?si=M5THkeRSfAVBSr6s')) {
                return NavigationDecision.prevent;
              } else if (request.url.startsWith('https://youtu.be/eGo4IYlbE5g?si=lR9e2JfjwZyXOGOd')) {
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

      try {
        // Ensure the amount is a valid integer
        int amountToAdd = int.parse(amount);

        // Update the wallet field in the found user's document
        await FirebaseFirestore.instance.collection('users').doc(documentID).update({
          'wallet': FieldValue.increment(amountToAdd), // Increment the wallet amount
        });

        print("Successfully added $amount to user ID: $scannedUserID's wallet.");
      } catch (e) {
        print('Error updating wallet: $e');
        throw e; // Rethrow to handle in the calling method
      }
    } else {
      throw Exception('User document does not exist for userID: $scannedUserID');
    }
  }

  Future<void> _proceedToSignOut() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<void> _logUserLogin(String userID, String firstName, String lastName) async {
    // Reference to the login document for the given userID
    DocumentReference loginDocRef = FirebaseFirestore.instance.collection('logintime').doc(userID);

    // Check if a document already exists for the given userID
    DocumentSnapshot userSnapshot = await loginDocRef.get();

    if (userSnapshot.exists) {
      // If the document exists, update the 'loggedOut' field to false
      await loginDocRef.update({
        'loggedOut': false,
        'scannedTime': FieldValue.serverTimestamp(), // Automatically set to the current server time
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Welcome back! You've successfully logged in.")),
      );
    } else {
      // If the document does not exist, create a new document for this user
      await loginDocRef.set({
        'firstName': firstName,
        'lastName': lastName,
        'loggedOut': false,
        'scannedQR': "http://www.FitTrack_Login.com",
        'scannedTime': FieldValue.serverTimestamp(), // Automatically set to the current server time
        'userID': userID,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You have successfully logged in for the first time!")),
      );
    }
  }

  Future<void> _logUserLogout(String recordID) async {
    await FirebaseFirestore.instance.collection('logintime').doc(recordID).update({
      'loggedOut': true,
      'scannedTime': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logout recorded successfully")),
    );
    _proceedToSignOut();
  }


  void _createQRCode(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateQRCodeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}