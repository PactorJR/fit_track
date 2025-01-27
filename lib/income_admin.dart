import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class IncomeAdminPage extends StatefulWidget {
  final String? userId;

  IncomeAdminPage({this.userId});

  @override
  _IncomeAdminPageState createState() => _IncomeAdminPageState();
}

class _IncomeAdminPageState extends State<IncomeAdminPage> {
  String? selectedUserId;
  TextEditingController searchController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  List<DocumentSnapshot> filteredDocs = [];
  String? selectedDay;

  @override
  void initState() {
    super.initState();
    selectedUserId = widget.userId ?? null;
    if (selectedUserId != null) {
      _selectUser(selectedUserId!);
    }
  }

  void _selectUser(String userId) {
    setState(() {
      selectedUserId = userId;
    });
  }

  Future<DateTime?> _selectDate(BuildContext context, {DateTime? initialDate}) async {
    DateTime initial = initialDate ?? DateTime.now();

    return await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  bool filterByDay(Timestamp scannedTime) {
    DateTime logDate = scannedTime.toDate();

    if (selectedDay != null && selectedDay != 'All') {
      String logDay = DateFormat('EEEE').format(logDate);
      if (logDay != selectedDay) {
        return false;
      }
    }

    if (startDate != null && endDate == null) {
      print("Waiting for End date to be chosen...");
      return false;
    }

    if (startDate != null && endDate != null) {
      bool withinRange = !logDate.isBefore(startDate!) && !logDate.isAfter(endDate!);
      if (!withinRange) {
        return false;
      }
    }

    return true;
  }

  @override
  Future<String> generateIncomeReport(List<DocumentSnapshot> filteredDocs) async {
    await _requestPermissions();

    String currentDateTime = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    String fitTrackPath = '/storage/emulated/0/FitTrack';
    String incomePath = '$fitTrackPath/IncomeReports';

    Directory incomeFolder = Directory(incomePath);
    if (!await incomeFolder.exists()) {
      await incomeFolder.create(recursive: true);
    }

    String filePath = '$incomePath/income_report_$currentDateTime.txt';
    String reportContent = 'Income Report - $currentDateTime\n\n';
    reportContent += 'Admin Name, User Name, Amount, Scanned Time\n';

    double totalIncome = 0.0;

    for (var doc in filteredDocs) {
      String adminName = doc['adminName'] ?? 'Unknown Admin';
      String userName = 'Unknown User';
      double amount = 0.0;
      String scannedTime = 'N/A';

      if (doc.reference.path.contains('guests')) {
        String firstName = doc['firstName'] ?? '';
        String lastName = doc['lastName'] ?? '';
        userName = '$firstName $lastName'.trim();
        amount = doc['amountPaid']?.toDouble() ?? 0.0;

        if (doc['timeStamp'] != null && doc['timeStamp'] is Timestamp) {
          scannedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format((doc['timeStamp'] as Timestamp).toDate());
        }
      } else {
        userName = doc['userName'] ?? 'Unknown User';
        amount = doc['amount']?.toDouble() ?? 0.0;

        if (doc['scannedTime'] != null && doc['scannedTime'] is Timestamp) {
          scannedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format((doc['scannedTime'] as Timestamp).toDate());
        }
      }

      totalIncome += amount;

      reportContent += '$adminName, $userName, \₱${amount.toStringAsFixed(2)}, $scannedTime\n';
    }

    reportContent += '\nTotal Income: \₱${totalIncome.toStringAsFixed(2)}\n';

    File file = File(filePath);
    await file.writeAsString(reportContent);

    return filePath;
  }

  Future<void> _requestPermissions() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      print("Storage permission granted");
    } else {
      print("Storage permission denied");
    }
  }


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
                  themeProvider.isDarkMode
                      ? 'assets/images/dark_bg.png'
                      : 'assets/images/bg.png',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people,
                    size: 24,
                    color: Colors.green,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Income Reporting',
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
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 600,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black38 : Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: Colors.black,
                          width: 2.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Users Information',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.filter_list,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                    SizedBox(width: 8),
                                    DropdownButton<String>(
                                      value: selectedDay,
                                      hint: Text('Select Day', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                                      icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white : Colors.black),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedDay = newValue;
                                        });
                                      },
                                      items: <String>[
                                        'All',
                                        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
                                      ].map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 20),
                                GestureDetector(
                                  onTap: () async {
                                    DateTime? pickedDate = await _selectDate(context, initialDate: startDate);
                                    if (pickedDate != null) {
                                      setState(() {
                                        startDate = pickedDate;
                                      });
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: isDarkMode ? Colors.white : Colors.black),
                                      SizedBox(width: 8),
                                      Text(
                                        startDate == null ? 'Start' : DateFormat('MM-dd').format(startDate!),
                                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 20),
                                GestureDetector(
                                  onTap: () async {
                                    DateTime? pickedDate = await _selectDate(context, initialDate: endDate);
                                    if (pickedDate != null) {
                                      setState(() {
                                        endDate = pickedDate;
                                      });
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: isDarkMode ? Colors.white : Colors.black),
                                      SizedBox(width: 8),
                                      Text(
                                        endDate == null ? 'End' : DateFormat('MM-dd').format(endDate!),
                                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                              ],
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance.collection('cashinlogs').snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Center(child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasError) {
                                        return Center(child: Text('Error: ${snapshot.error}'));
                                      }

                                      return StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance.collection('guests').snapshots(),
                                        builder: (context, guestsSnapshot) {
                                          if (guestsSnapshot.connectionState == ConnectionState.waiting) {
                                            return Center(child: CircularProgressIndicator());
                                          }
                                          if (guestsSnapshot.hasError) {
                                            return Center(child: Text('Error: ${guestsSnapshot.error}'));
                                          }
                                          if (!guestsSnapshot.hasData || guestsSnapshot.data!.docs.isEmpty && !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                            return Center(child: Text('No Income data found.'));
                                          }

                                          List<DocumentSnapshot> combinedDocs = [];
                                          List<DocumentSnapshot> filteredCashinLogs = snapshot.data!.docs.where((doc) {
                                            if (doc['scannedTime'] == null || !(doc['scannedTime'] is Timestamp)) {
                                              return false;
                                            }

                                            DateTime logDate = (doc['scannedTime'] as Timestamp).toDate();

                                            if (startDate != null && endDate != null) {
                                              if (logDate.isBefore(startDate!) || logDate.isAfter(endDate!)) {
                                                return false;
                                              }
                                            }

                                            if (selectedDay != null && selectedDay != 'All') {
                                              String dayOfWeek = DateFormat('EEEE').format(logDate);
                                              if (dayOfWeek != selectedDay) {
                                                return false;
                                              }
                                            }

                                            return true;
                                          }).toList();

                                          List<DocumentSnapshot> filteredGuests = guestsSnapshot.data!.docs;
                                          combinedDocs.addAll(filteredCashinLogs);
                                          combinedDocs.addAll(filteredGuests);

                                          filteredDocs = combinedDocs;

                                          if (combinedDocs.isEmpty) {
                                            return Center(
                                              child: Text('No data found for the selected filters', style: TextStyle(color: Colors.red, fontSize: 16)),
                                            );
                                          }

                                          return Table(
                                            border: TableBorder.all(),
                                            columnWidths: {
                                              0: FixedColumnWidth(120),
                                              1: FixedColumnWidth(120),
                                              2: FixedColumnWidth(80),
                                              3: FixedColumnWidth(100),
                                            },
                                            children: [
                                              TableRow(
                                                children: [
                                                  Container(height: 40, alignment: Alignment.center, child: Text('Admin Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Container(height: 40, alignment: Alignment.center, child: Text('User/Guest Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Container(height: 40, alignment: Alignment.center, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Container(height: 40, alignment: Alignment.center, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                                ],
                                              ),
                                              ...combinedDocs.map((doc) {
                                                var data = doc.data() as Map<String, dynamic>;

                                                return TableRow(
                                                  decoration: BoxDecoration(
                                                    color: selectedUserId == doc.id ? Colors.white.withOpacity(0.8) : Colors.transparent,
                                                  ),
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        _selectUser(doc.id);
                                                        FirebaseFirestore.instance.collection('cashinlogs').doc(doc.id).update({'seen': true});
                                                      },
                                                      child: Container(height: 40, alignment: Alignment.center, child: Text(data['adminName'] ?? 'N/A')),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        _selectUser(doc.id);
                                                      },
                                                      child: Container(
                                                        height: 40,
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          data['userName'] ?? '${data['firstName']} ${data['lastName']}' ?? 'N/A',
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        _selectUser(doc.id);
                                                      },
                                                      child: Container(
                                                        height: 40,
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          data.containsKey('amount')
                                                              ? '\$${data['amount']}'
                                                              : (data.containsKey('amountPaid') ? '\$${data['amountPaid']}' : 'Not available'),
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        _selectUser(doc.id);
                                                      },
                                                      child: Container(
                                                        height: 40,
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          data.containsKey('scannedTime') && data['scannedTime'] != null
                                                              ? DateFormat('MM-dd-yyyy').format(
                                                              (data['scannedTime'] as Timestamp).toDate())
                                                              : 'Not available',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(top: 0.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16.0),
                                      ),
                                      side: BorderSide(color: Colors.green),
                                      elevation: 0,
                                    ),
                              onPressed: () async {
                                print("Button pressed. Checking filteredDocs...");

                                if (filteredDocs.isNotEmpty) {
                                  print("Filtered Docs is not empty. Proceeding to generate report...");


                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Generating Report"),
                                        content: Row(
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(width: 16),
                                            Expanded(child: Text("Please wait while the report is being generated...")),
                                          ],
                                        ),
                                      );
                                    },
                                  );


                                  String filePath = await generateIncomeReport(filteredDocs);


                                  Navigator.of(context).pop();


                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Report Generated"),
                                        content: Text("The report has been successfully generated.\n\nLocation:\n$filePath"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text("OK"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                    } else {
                                      print("Filtered Docs is empty. Displaying No Data message...");


                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text("No Data"),
                                            content: Text("No data available to generate the report."),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text("OK"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }


                                    print("Filtered Docs length: ${filteredDocs.length}");
                                  },


                                      child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Icon(Icons.edit_note_outlined, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text(
                                          'Generate a Report',
                                          style: TextStyle(color: Colors.green),
                                        ),
                                      ],
                                    ),
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
        ],
      ),
    );
  }
}