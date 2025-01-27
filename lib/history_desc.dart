import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'theme_provider.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

@override
void initState() {
}

class HistoryDescPage extends StatefulWidget {
  final Map<String, dynamic> logData;
  final String transactionId;

  HistoryDescPage({required this.logData, required this.transactionId});

  @override
  _HistoryDescPageState createState() => _HistoryDescPageState();
}

class _HistoryDescPageState extends State<HistoryDescPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    final logData = widget.logData;
    final transactionId = widget.transactionId;
    final timestamp = (logData?['scannedTime'] as Timestamp?)?.toDate();
    final isLogin = logData?['scannedQR'] == 'http://www.FitTrack_Login.com';
    final isLogout = logData?['scannedQR'] == 'http://www.FitTrack_Logout.com';
    final isCashInLog = logData?.containsKey('amount') ?? false;

    final Color containerColor = isLogin
        ? Colors.green.withOpacity(0.9)
        : isLogout
        ? Colors.red.withOpacity(0.9)
        : isCashInLog
        ? Colors.blue.withOpacity(0.9)
        : Colors.grey.withOpacity(0.9);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  themeProvider.isDarkMode
                      ? 'assets/images/dark_bg.png'
                      : 'assets/images/bg.png',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_edu, size: 24, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'History Description',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: isDarkMode ? Colors.grey : Colors.green,
              onPressed: () {
                Navigator.of(context)
                    .pop();
              },
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLogin
                        ? "Log-in"
                        : isLogout
                        ? "Log-out"
                        : isCashInLog
                        ? "Cash-in"
                        : "Unknown Log",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Details:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isCashInLog
                        ? "Amount: ₱${logData?['amount'] ?? 0}\nCashed-in by: ${logData?['adminName'] ?? 'Unknown Admin'}\nTimestamp: ${timestamp != null ? DateFormat('EEEE, MMMM dd, yyyy hh:mm a').format(timestamp) : 'N/A'}"
                        : "Timestamp: ${timestamp != null ? DateFormat('EEEE, MMMM dd, yyyy hh:mm a').format(timestamp) : 'N/A'}",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Transaction ID: $transactionId',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

