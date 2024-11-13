import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CreateQRCodeScreen extends StatefulWidget {
  @override
  _CreateQRCodeScreenState createState() => _CreateQRCodeScreenState();
}

class _CreateQRCodeScreenState extends State<CreateQRCodeScreen> {
  String _qrData = ''; // Data to generate QR code

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: _qrData.isEmpty
                          ? Text(
                        "Enter data to generate QR code",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      )
                          : QrImageView(
                        data: _qrData, // Data for the QR code
                        version: QrVersions.auto,
                        size: 200.0, // QR code size
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Enter Data",
                        hintStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.5), // Darker background for visibility
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          _qrData = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40, // Position the button at the top
            left: 20, // Align to the left
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
}
