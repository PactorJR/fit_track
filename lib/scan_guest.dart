import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';

class ScanGuest extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String age;
  final String userType;

  ScanGuest({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.age,
    required this.userType,
  });

  @override
  _ScanGuestState createState() => _ScanGuestState();
}

class _ScanGuestState extends State<ScanGuest> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  String _result = '';
  DateTime? _lastScanTime;
  Timer? _debounce;

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
    super.dispose();
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
                    borderColor: Colors.green.shade800,
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
                  color: Colors.green,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome, ${widget.firstName} ${widget.lastName}!',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _result.isEmpty
                            ? 'Scan a QR code to proceed'
                            : 'Result: $_result',
                        style: TextStyle(fontSize: 18, color: Colors.white),
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
              backgroundColor: Colors.blue,
              onPressed: () {
                Navigator.pop(context);
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
      if (_shouldProcessScan(scanData.code)) {
        if (_debounce?.isActive ?? false) {
          _debounce?.cancel();
        }

        _debounce = Timer(Duration(seconds: 1), () async {
          setState(() {
            _result = scanData.code ?? 'Unknown QR code';
          });

          if (_isValidQRLink(scanData.code)) {
            await _saveGuestData();
          } else {
            _showInvalidQRDialog();
          }
        });
      }
    });
  }

  bool _shouldProcessScan(String? code) {
    final now = DateTime.now();
    if (_lastScanTime == null || now.difference(_lastScanTime!).inSeconds > 2) {
      _lastScanTime = now;
      return true;
    }
    return false;
  }

  bool _isValidQRLink(String? code) {
    return code != null && code == "http://www.FitTrack_Login.com";
  }

  Future<void> _saveGuestData() async {
    try {
      QuerySnapshot guestSnapshot = await FirebaseFirestore.instance
          .collection('guests')
          .where('firstName', isEqualTo: widget.firstName)
          .where('lastName', isEqualTo: widget.lastName)
          .get();

      if (guestSnapshot.docs.isNotEmpty) {
        DocumentSnapshot guestDoc = guestSnapshot.docs.first;
        await guestDoc.reference.update({
          'loginQR': guestDoc.id,
        });

        print("Updated existing guest data with loginQR field.");


        _showSuccessDialog(guestDoc.id);
      } else {
        Map<String, dynamic> guestData = {
          'firstName': widget.firstName,
          'lastName': widget.lastName,
          'phoneNumber': int.tryParse(widget.phoneNumber) ?? 0,
          'age': int.tryParse(widget.age) ?? 0,
          'userType': widget.userType,
          'amountPaid': 30,
          'timestamp': FieldValue.serverTimestamp(),
        };

        DocumentReference guestRef = await FirebaseFirestore.instance.collection('guests').add(guestData);

        await guestRef.update({
          'loginQR': guestRef.id,
        });

        print("Added new guest data and set loginQR field.");


        _showSuccessDialog(guestRef.id);
      }

      await _controller?.pauseCamera();
      _debounce?.cancel();

    } catch (e) {
      print("Error saving guest data: $e");
      _showErrorDialog();
    }
  }

  Future<void> _generateAndShowQRCode(String guestId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Guest QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                width: 200.0,
                height: 200.0,
                child: QrImageView(
                  data: guestId,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              SizedBox(height: 20),
              Text('Scan this QR code for guest login.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showInvalidQRDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invalid QR Code'),
        content: Text('Please scan a valid FitTrack QR code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text('Guest data saved successfully!'),
        actions: [
          TextButton(
            onPressed: () {

              Navigator.pop(context);
              _generateAndShowQRCode(documentId);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }


  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('Failed to save guest data. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}