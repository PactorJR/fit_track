import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:io';

class GuestPage extends StatefulWidget {
  @override
  _GuestPageState createState() => _GuestPageState();
}

class _GuestPageState extends State<GuestPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? userType;
  String? selectedDepartment;
  String successMessage = "";
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> submitData() async {
    Map<String, dynamic> guestData = {
      'firstName': firstNameController.text.trim(),
      'lastName': lastNameController.text.trim(),
      'age': ageController.text.trim(),
      'phoneNumber': phoneController.text.trim(),
      'userType': userType,
      'department': selectedDepartment,
    };

    try {
      await firestore.collection('guests').add(guestData);
      firstNameController.clear();
      lastNameController.clear();
      ageController.clear();
      phoneController.clear();
      setState(() {
        userType = null;
        selectedDepartment = null;
        successMessage = "User information submitted successfully!";
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScanGuest(
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        successMessage = "Error submitting data, please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Guest')),
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
          Center(
            child: Container(
              width: 300,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: firstNameController, decoration: InputDecoration(labelText: 'First Name')),
                  TextField(controller: lastNameController, decoration: InputDecoration(labelText: 'Last Name')),
                  TextField(controller: ageController, decoration: InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
                  TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
                  DropdownButtonFormField<String>(
                    value: userType,
                    hint: Text('Select User Type'),
                    items: ['Student', 'Faculty'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => setState(() {
                      userType = value;
                      selectedDepartment = null;
                    }),
                  ),
                  if (userType != null)
                    DropdownButtonFormField<String>(
                      value: selectedDepartment,
                      hint: Text('Select Department'),
                      items: [
                        'Department of Art and Sciences',
                        'Department of Computer Studies',
                        'Department of Industrial Technology',
                        'Department of Engineering',
                        'Department of Management Studies',
                        'Department of Teacher Education',
                      ].map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                      onChanged: (value) => setState(() => selectedDepartment = value),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(onPressed: submitData, child: Text('Submit')),
                  SizedBox(height: 10),
                  if (successMessage.isNotEmpty)
                    Text(successMessage, style: TextStyle(color: successMessage.contains("Error") ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanGuest extends StatefulWidget {
  final String firstName;
  final String lastName;

  ScanGuest({required this.firstName, required this.lastName});

  @override
  _QRScannerState createState() => _QRScannerState();
}

class _QRScannerState extends State<ScanGuest> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  String _result = '';
  Timer? _debounce;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _controller?.pauseCamera();
    }
    _controller?.resumeCamera();
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(Duration(seconds: 1), () => _handleScannedData(scanData.code!));
    });
  }

  Future<void> _handleScannedData(String code) async {
    setState(() => _result = code);
    if (!code.contains("FitTrack")) {
      _showMessage("Unknown QR code scanned");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage("No user logged in");
      return;
    }

    if (code.contains("http://www.FitTrack_Login.com")) {
      await _processLogin();
    } else if (code.contains("http://www.FitTrack_Logout.com")) {
      await _processLogout();
    }
  }

  Future<void> _processLogin() async {
    final loginData = {
      'firstName': widget.firstName,
      'lastName': widget.lastName,
      'loggedOut': false,
      'scannedQR': _result,
      'scannedTime': Timestamp.now(),
      'userID': 'Guest',
    };

    final recentLogin = await FirebaseFirestore.instance.collection('logintime')
        .orderBy('scannedTime', descending: true)
        .limit(1)
        .get();

    if (recentLogin.docs.isNotEmpty && !(recentLogin.docs.first['loggedOut'] ?? true)) {
      _showMessage("You are already logged in!");
    } else {
      await _addGuestToLogintime(loginData);
    }
  }

  Future<void> _processLogout() async {
    // Add logout functionality if needed
  }

  Future<void> _addGuestToLogintime(Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('logintime').add(data);
      _showMessage("Login recorded successfully!");
    } catch (e) {
      _showMessage("Error logging in: $e");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                  overlay: QrScannerOverlayShape(borderColor: Colors.red, borderRadius: 10, borderLength: 30, borderWidth: 10, cutOutSize: 300),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(child: Text(_result.isEmpty ? 'Scan a code' : 'Scanned: $_result', style: TextStyle(fontSize: 20))),
              ),
            ],
          ),
          Positioned(
            top: 40,
            left: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.green,
              onPressed: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
