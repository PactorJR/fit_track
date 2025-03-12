import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'dart:io';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'home_page_admin.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';


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
  late WebViewController _webViewController;
  User? currentUser = FirebaseAuth.instance.currentUser;
  Timer? _resetTimer;
  String? _authCode;
  DateTime? _lastSentTime;
  TextEditingController? codeController = TextEditingController();
  bool canResend = true;


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
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider
        .of<ThemeProvider>(context)
        .isDarkMode;
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
                    borderColor: Colors.green,
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
                  width: double.infinity,
                  height: double.infinity,
                  color: isDarkMode
                      ? Colors.white
                      : Colors.green[700],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 30, color: isDarkMode
                          ? Colors.black
                          : Colors.white),
                      SizedBox(width: 10),
                      Text(
                        _result.isEmpty
                            ? 'Scan a QR code'
                            : 'Scanned Successfully',
                        style: TextStyle(
                          fontSize: 20,
                          color: isDarkMode
                              ? Colors.black
                              : Colors.white,
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
            top: 40,
            left: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: isDarkMode ? Colors.grey : Colors.green,
              onPressed: () {
                Navigator.pop(context);
                _controller?.dispose();
                _debounce?.cancel();
                _controller?.pauseCamera();
              },
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(User user, String firstName, String lastName) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      _showSnackbar("User not found in 'users' collection.");
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
        _showSnackbar("You are already logged in!");
        return;
      }
    }

    _authCode = _generateAuthCode();
    _lastSentTime = DateTime.now();
    await _sendEmail(user.email!, _authCode!);
    _showAuthDialog(context, user, actualUserID, firstName, lastName);
  }


  void _showAuthDialog(BuildContext context, User user, String userID, String firstName, String lastName) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isDarkMode = themeProvider.isDarkMode;

    _controller?.dispose();
    _debounce?.cancel();
    _controller?.pauseCamera();

    TextEditingController codeController = TextEditingController();
    bool canResend = true;
    int remainingTime = 60;
    Timer? countdownTimer;

    void startCountdown() {
      countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (remainingTime > 0) {
          setState(() {
            remainingTime--;
          });
        } else {
          setState(() {
            canResend = true;
          });
          countdownTimer?.cancel();
        }
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? Colors.white : Colors.black,
              title: Text(
                "Enter OTP",
                style: TextStyle(color: isDarkMode ? Colors.black : Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: "Enter 6-digit OTP",
                      hintStyle: TextStyle(color: isDarkMode ? Colors.grey : Colors.black54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDarkMode ? Colors.grey : Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDarkMode ? Colors.green : Colors.blue),
                      ),
                    ),
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        onPressed: canResend
                            ? () async {
                          setState(() {
                            canResend = false;
                            remainingTime = 60;
                          });
                          _authCode = _generateAuthCode();
                          _lastSentTime = DateTime.now();
                          await _sendEmail(user.email!, _authCode!);
                          startCountdown();
                        }
                            : null,
                        child: Text(
                          "Resend OTP",
                          style: TextStyle(color: isDarkMode ? Colors.black : Colors.green),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        canResend ? "" : "Retry in $remainingTime sec",
                        style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey[500] : Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: isDarkMode ? Colors.black : Colors.green),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (codeController.text == _authCode) {
                      Navigator.pop(context);
                      _processLogin(user, userID, firstName, lastName);
                    } else {
                      _showSnackbar("Incorrect OTP. Try again.");
                    }
                  },
                  child: Text(
                    "Verify",
                    style: TextStyle(color: isDarkMode ? Colors.black : Colors.green),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }



  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendEmail(String email, String otp) async {
    final smtpServer = gmail('jr.pactor@cvsu.edu.ph', 'ncfhexuxtmhynjay');

    final message = Message()
      ..from = Address('FitTrackCCAT@gmail.com', 'FitTrack')
      ..recipients.add(email)
      ..subject = 'Your One-Time Password'
      ..text = 'Your one-time password is: $otp';

    try {
      await send(message, smtpServer);
      print("Email sent successfully.");
    } catch (e) {
      print("Failed to send email: $e");
    }
  }

  String _generateAuthCode() {
    final randomBytes = List<int>.generate(6, (i) => Random.secure().nextInt(256));
    final hash = sha256.convert(randomBytes);
    final otp = (int.parse(hash.toString().substring(0, 6), radix: 16) % 900000) + 100000;
    print(otp);
    return otp.toString();
  }

  Future<void> _processLogin(User user, String actualUserID, String firstName,
      String lastName) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      double walletBalance = (userDoc['wallet'] is int)
          ? (userDoc['wallet'] as int).toDouble()
          : userDoc['wallet'] ?? 0.0;

      if (walletBalance >= 30.0) {
        double newBalance = walletBalance - 30;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'wallet': newBalance});

        QuerySnapshot loginRecord = await FirebaseFirestore.instance
            .collection('logintime')
            .where('userID', isEqualTo: actualUserID)
            .orderBy('scannedTime', descending: true)
            .limit(1)
            .get();

        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("User is not authenticated."),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'loggedStatus': true});

        await _logUserLogin(firstName, lastName);

        if (loginRecord.docs.isNotEmpty) {
          await loginRecord.docs.first.reference.update({'loggedOut': false});
        } else {
          await FirebaseFirestore.instance.collection('logintime').add({
            'userID': actualUserID,
            'firstName': firstName,
            'lastName': lastName,
            'scannedTime': Timestamp.now(),
            'loggedOut': false,
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Insufficient balance. Please add funds to your wallet."),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User not found."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _controller = controller;
    });

    controller.scannedDataStream.listen((scanData) async {
      final code = scanData.code!;
      setState(() {
        _result = code;
      });

      _debounce?.cancel();
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
          _controller?.resumeCamera();
          return;
        }

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
          _controller?.resumeCamera();
          return;
        }

        String firstName = userDoc['firstName'] ?? 'Unknown';
        String lastName = userDoc['lastName'] ?? 'Unknown';
        String userType = userDoc['userType'] ?? 'User';

        bool qrHandled = false;
        bool shouldNavigate = true;

        final regex = RegExp(r'^(20[2-9]\d{2}\d+)$');
        final match = regex.firstMatch(code);

        if (match != null && match.groupCount == 1) {
          await _handleAmountAddition(code, user, userType);
          qrHandled = true;
        }

        if (!qrHandled) {
          if (code.contains("http://www.FitTrack_Login.com")) {
            _handleLogin(user, firstName, lastName);
            qrHandled = true;
            shouldNavigate = true;
          } else if (code.contains("http://www.FitTrack_Logout.com")) {
            _handleLogout(user);
            qrHandled = true;
            shouldNavigate = false;
          }
        }

        if (!qrHandled) {
          QuerySnapshot equipmentSnapshot = await FirebaseFirestore.instance
              .collection('equipments')
              .where('equipLink', isEqualTo: code)
              .get();

          if (equipmentSnapshot.docs.isNotEmpty) {
            String link = equipmentSnapshot.docs.first['equipLink'];
            await _launchURL(context, link);
            qrHandled = true;
            shouldNavigate = true;
            print("navigating to launchurl");
          } else {
            QuerySnapshot guestSnapshot = await FirebaseFirestore.instance
                .collection('guests')
                .where('loginQR', isEqualTo: code)
                .get();

            if (guestSnapshot.docs.isNotEmpty) {
              String guestDocId = guestSnapshot.docs.first.id;
              bool hasPaid = await _askAdminForPaymentStatus(guestDocId);
              if (hasPaid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment confirmed for guest'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment not confirmed for guest'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              qrHandled = true;
            }
          }
        }

        if (!qrHandled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unknown QR Code'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
              margin: EdgeInsets.all(16),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (shouldNavigate) {
          if (userType == 'Admin') {
            _controller?.dispose();
            _debounce?.cancel();
            _controller?.pauseCamera();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MyAdminHomePage(title: 'Admin Dashboard'),
              ),
            );
          } else {
            _controller?.dispose();
            _debounce?.cancel();
            _controller?.pauseCamera();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MyHomePage(
                      title: 'Home',
                      cameFromScanPage: true,
                    ),
              ),
            );
          }
        }
      });
    });
  }

  Future<bool> _askAdminForPaymentStatus(String guestDocId) async {
    User? user = FirebaseAuth.instance.currentUser;
    String adminName = 'Unknown';
    if (user != null) {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (adminDoc.exists) {
        String firstName = adminDoc['firstName'] ?? 'Unknown';
        String lastName = adminDoc['lastName'] ?? 'Unknown';
        adminName = '$firstName $lastName';

        await FirebaseFirestore.instance
            .collection('guests')
            .doc(guestDocId)
            .update({'adminName': adminName});

        return true;
      }
    }

    bool? hasPaid = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Payment Verification"),
          content: Text("Has the guest successfully paid?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Yes"),
            ),
          ],
        );
      },
    );

    if (hasPaid == true) {
      await FirebaseFirestore.instance
          .collection('guests')
          .doc(guestDocId)
          .update({
        'amountPaid': 30,
        'adminName': adminName,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guest successfully paid'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update amount: $error'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      });
    }

    return hasPaid ?? false;
  }

  Future<void> _handleLogout(User user) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not found in 'users' collection."),
            behavior: SnackBarBehavior.floating,
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

      if (loginRecord.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No login records found for this user."),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      DocumentSnapshot lastRecord = loginRecord.docs.first;
      bool loggedOut = lastRecord['loggedOut'] ?? false;

      if (loggedOut) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You are already logged out!"),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(title: 'Home')),
        );
      } else {
        await _logUserLogout(lastRecord.id);
      }
    } catch (e) {
      print("Error handling logout: $e");
    }
  }

  Future<void> _logUserLogout(String recordID) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("User is not authenticated.");
        return;
      }

      DocumentReference userDocRef = FirebaseFirestore.instance.collection(
          'users').doc(currentUser.uid);
      DocumentSnapshot userSnapshot = await userDocRef.get();

      if (!userSnapshot.exists) {
        print("User data not found.");
        return;
      }

      String actualUserID = userSnapshot['userID'] ?? '';
      String firstName = userSnapshot['firstName'] ?? '';
      String lastName = userSnapshot['lastName'] ?? '';

      DocumentReference loginDocRef = FirebaseFirestore.instance.collection(
          'logintime').doc(recordID);

      DocumentSnapshot loginSnapshot = await loginDocRef.get();

      if (loginSnapshot.exists) {
        String getDayName(int weekday) {
          switch (weekday) {
            case 1:
              return 'monday';
            case 2:
              return 'tuesday';
            case 3:
              return 'wednesday';
            case 4:
              return 'thursday';
            case 5:
              return 'friday';
            case 6:
              return 'saturday';
            case 7:
              return 'sunday';
            default:
              return '';
          }
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'loggedStatus': false});

        await FirebaseFirestore.instance.collection('loghistory').add({
          'firstName': firstName,
          'lastName': lastName,
          'scannedQR': "http://www.FitTrack_Logout.com",
          'scannedTime': FieldValue.serverTimestamp(),
          'seen': false,
          'type': "logout",
          'day': getDayName(DateTime
              .now()
              .weekday),
          'userID': actualUserID,
        });

        await loginDocRef.update({
          'loggedOut': true,
          'scannedTime': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance.collection('logouttime').doc(
            actualUserID).set({
          'firstName': firstName,
          'lastName': lastName,
          'loggedIn': 'false',
          'scannedQR': "http://www.FitTrack_Logout.com",
          'scannedTime': FieldValue.serverTimestamp(),
          'userID': actualUserID,
        });

        bool shouldSignOut = await showLogoutConfirmationDialog();
        if (shouldSignOut) {
          await _proceedToSignOut();
        } else {
          _controller?.dispose();
          _debounce?.cancel();
          _controller?.pauseCamera();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MyHomePage(
                    title: 'Home',
                    cameFromScanPage: true,
                  ),
            ),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout successful'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
            margin: EdgeInsets.all(16),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print("No login record found for this user.");
      }
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  Future<bool> showLogoutConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout Confirmation'),
          content: Text('Do you want to log out from the app as well?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed
  }

  Future<void> _proceedToSignOut() async {
    await FirebaseAuth.instance.signOut();
    _controller?.dispose();
    _debounce?.cancel();
    _controller?.pauseCamera();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _launchURL(BuildContext context, String scannedUrl) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('equipments')
        .where('equipLink', isEqualTo: scannedUrl)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;
      String link = doc['equipLink'];
      String title = doc['equipTitle'];

      // Use post-frame callback to ensure dialog is displayed after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWorkoutDialog(context, title, link);
        print("navigating to _showWorkoutDialog");
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unknown QR Code'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
          margin: EdgeInsets.all(16),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWorkoutDialog(BuildContext context, String title, String link) {
    Map<String, List<String>> titleToGifs = {
      "Abs": [
        "assets/workouts/Abs1.gif",
        "assets/workouts/Abs2.gif",
        "assets/workouts/Abs3.gif",
      ],
      "Arms": [
        "assets/workouts/Arms1.gif",
        "assets/workouts/Arms2.gif",
        "assets/workouts/Arms3.gif",
      ],
      "Cardio": [
        "assets/workouts/Cardio1.gif",
        "assets/workouts/Cardio2.gif",
      ],
      "Chest": [
        "assets/workouts/Chest1.gif",
        "assets/workouts/Chest2.gif",
        "assets/workouts/Chest3.gif",
      ],
      "Back": [
        "assets/workouts/Back1.gif",
        "assets/workouts/Back2.gif",
      ],
    };

    List<String> gifs = titleToGifs[title] ?? [];
    String previewGif = gifs.isNotEmpty ? gifs[0] : ""; // Initialize preview with the first gif

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title, textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Large preview area
                  previewGif.isNotEmpty
                      ? GestureDetector(
                    onTap: () {
                      // Optionally, you can add logic here to enlarge the gif preview
                    },
                    child: Image.asset(
                      previewGif,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container(),
                  SizedBox(height: 12),

                  // Small circle buttons for each GIF
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: gifs.map((gif) {
                        return GestureDetector(
                          onTap: () {
                            // Update the preview to the selected gif
                            setState(() {
                              previewGif = gif;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: previewGif == gif
                                  ? Border.all(color: Colors.green, width: 2)  // Green border if selected
                                  : Border.all(color: Colors.transparent),     // Transparent border if not selected
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ClipOval( // Ensures GIF remains circular, even without border
                                child: Image.asset(
                                  gif,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog first
                      _openLink(context, link); // Then navigate
                    },
                    child: Text("Go to Video", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _gifButton(BuildContext context, String assetPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Image.asset(assetPath, height: 100, fit: BoxFit.cover),
    );
  }



  void _openLink(BuildContext context, String link) async {
    final Uri _url = Uri.parse(link);
    if (await canLaunchUrl(_url)) {
      await launchUrl(_url, mode: LaunchMode.externalApplication);
    } else {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(link));

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


  Future<void> _handleAmountAddition(String code, User user,
      String userType) async {
    if (userType != 'Admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Only administrators can add amounts to wallets."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final regex = RegExp(r'^(20[2-9]\d{2}\d+)$');
    final match = regex.firstMatch(code);

    if (match != null && match.groupCount == 1) {
      String scannedUserID = match.group(1)!;

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

        bool? isFinalConfirmation = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm Amount"),
              content: Text(
                  "Are you sure you want to add $amount to user ID: $scannedUserID's wallet?"),
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
          await _addAmountToWallet(scannedUserID, amount);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Added $amount to user ID: $scannedUserID's wallet."),
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

  Future<void> _addAmountToWallet(String scannedUserID, String amount) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("No user is logged in.");
      return;
    }

    QuerySnapshot scannedUserQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('userID', isEqualTo: scannedUserID)
        .get();

    if (scannedUserQuery.docs.isNotEmpty) {
      DocumentSnapshot scannedUserDoc = scannedUserQuery.docs.first;
      String documentID = scannedUserDoc.id;

      String adminID = currentUser.uid;

      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminID)
          .get();

      String adminName = '';
      if (adminDoc.exists) {
        adminName = '${adminDoc['firstName']} ${adminDoc['lastName']}';
      }

      String userName = '${scannedUserDoc['firstName']} ${scannedUserDoc['lastName']}';

      try {
        int amountToAdd = int.parse(amount);

        await FirebaseFirestore.instance.collection('users')
            .doc(documentID)
            .update({
          'wallet': FieldValue.increment(amountToAdd),
        });

        print(
            "Successfully added $amount to user ID: $scannedUserID's wallet.");

        await FirebaseFirestore.instance.collection('cashinlogs').add({
          'adminID': adminID,
          'adminName': adminName,
          'amount': amountToAdd,
          'userID': scannedUserID,
          'userName': userName,
          'scannedTime': FieldValue.serverTimestamp(),
          'seen': false,
        });

        print(
            "Cash-in transaction logged successfully for user ID: $scannedUserID.");
      } catch (e) {
        print('Error updating wallet: $e');
        throw e;
      }
    } else {
      throw Exception(
          'User document does not exist for userID: $scannedUserID');
    }
  }

  Future<void> _logUserLogin(String firstName, String lastName) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User is not authenticated."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    DocumentReference userDocRef = FirebaseFirestore.instance.collection(
        'users').doc(currentUser.uid);

    DocumentSnapshot userSnapshot = await userDocRef.get();

    if (!userSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User data not found."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    String actualUserID = userSnapshot['userID'] ?? '';

    DocumentReference loginDocRef = FirebaseFirestore.instance
        .collection('logintime')
        .doc(actualUserID);

    DocumentSnapshot loginSnapshot = await loginDocRef.get();

    if (loginSnapshot.exists) {
      await loginDocRef.update({
        'loggedIn': true,
        'scannedTime': FieldValue.serverTimestamp() ?? Timestamp.now(),
      });

      await FirebaseFirestore.instance.collection('loghistory').add({
        'firstName': firstName,
        'lastName': lastName,
        'scannedQR': "http://www.FitTrack_Login.com",
        'scannedTime': FieldValue.serverTimestamp() ?? Timestamp.now(),
        'seen': false,
        'type': "login",
        'day': getDayName(DateTime
            .now()
            .weekday),
        'userID': actualUserID,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Welcome back! You've successfully logged in."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      DocumentReference loginDocRef = FirebaseFirestore.instance
          .collection('logintime')
          .doc(actualUserID);

      await loginDocRef.set({
        'firstName': firstName,
        'lastName': lastName,
        'loggedOut': false,
        'scannedQR': "http://www.FitTrack_Login.com",
        'scannedTime': FieldValue.serverTimestamp(),
        'userID': actualUserID,
      });

      await FirebaseFirestore.instance.collection('loghistory').add({
        'firstName': firstName,
        'lastName': lastName,
        'scannedQR': "http://www.FitTrack_Login.com",
        'scannedTime': FieldValue.serverTimestamp(),
        'seen': false,
        'type': "login",
        'day': getDayName(DateTime
            .now()
            .weekday),
        'userID': actualUserID,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You have successfully logged in."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return '';
    }
  }
}