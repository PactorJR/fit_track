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
    // If no date is provided, set initialDate to today's date
    DateTime initial = initialDate ?? DateTime.now();

    return await showDatePicker(
      context: context,
      initialDate: initial, // Use provided initialDate or default to today
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

    // Check if a specific day of the week is selected
    if (selectedDay != null && selectedDay != 'All') {
      String logDay = DateFormat('EEEE').format(logDate); // Get full day name
      if (logDay != selectedDay) {
        return false; // Exclude logs that don't match the selected day
      }
    }

    // Check if the startDate is chosen but the endDate is not selected
    if (startDate != null && endDate == null) {
      print("Waiting for End date to be chosen...");
      return false;
    }

    // Filter by date range: Only show logs within the range
    if (startDate != null && endDate != null) {
      bool withinRange = !logDate.isBefore(startDate!) && !logDate.isAfter(endDate!);
      if (!withinRange) {
        return false; // Exclude logs outside the date range
      }
    }

    return true; // Include logs that meet all criteria
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
      String userName = doc['userName'] ?? 'Unknown User';
      double amount = doc['amount']?.toDouble() ?? 0.0;
      String scannedTime = doc['scannedTime'] != null && doc['scannedTime'] is Timestamp
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format((doc['scannedTime'] as Timestamp).toDate())
          : 'N/A';

      totalIncome += amount;

      reportContent += '$adminName, $userName, \$${amount.toStringAsFixed(2)}, $scannedTime\n';
    }

    reportContent += '\nTotal Income: \$${totalIncome.toStringAsFixed(2)}\n';

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
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                // Switch between background images based on the dark mode
                image: AssetImage(
                  themeProvider.isDarkMode
                      ? 'assets/images/dark_bg.png' // Dark mode background
                      : 'assets/images/bg.png',    // Light mode background
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Title at the top
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

          // Centered content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16.0),
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
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Dropdown for Day Selection
                                Row(
                                  children: [
                                    Icon(Icons.filter_list, color: Colors.white), // Filter icon
                                    SizedBox(width: 8),
                                    DropdownButton<String>(
                                      value: selectedDay,
                                      hint: Text('Select Day', style: TextStyle(color: Colors.white)),
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
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
                                          child: Text(value, style: TextStyle(color: Colors.black)),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 20),

                                // Start Date Picker
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
                                      Icon(Icons.calendar_today, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        startDate == null ? 'Start' : DateFormat('MM-dd').format(startDate!),
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 20),

                                // End Date Picker
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
                                      Icon(Icons.calendar_today, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        endDate == null ? 'End' : DateFormat('MM-dd').format(endDate!),
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                              ],
                            ),
                            SizedBox(height: 8),

                            SingleChildScrollView(
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
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return Center(child: Text('No income found.'));
                                  }

                                  // Filter the documents based on the selected day and date range
                                  List<DocumentSnapshot> localFilteredDocs = snapshot.data!.docs.where((doc) {
                                    if (doc['scannedTime'] == null || !(doc['scannedTime'] is Timestamp)) {
                                      return false; // Exclude documents without valid timestamps
                                    }

                                    // Convert Timestamp to DateTime
                                    DateTime logDate = (doc['scannedTime'] as Timestamp).toDate();

                                    // Apply date range filter
                                    if (startDate != null && endDate != null) {
                                      if (logDate.isBefore(startDate!) || logDate.isAfter(endDate!)) {
                                        return false; // Exclude logs outside the range
                                      }
                                    }

                                    // Apply day filter
                                    if (selectedDay != null && selectedDay != 'All') {
                                      String dayOfWeek = DateFormat('EEEE').format(logDate); // Get the day of the week
                                      if (dayOfWeek != selectedDay) {
                                        return false; // Exclude logs that don't match the selected day
                                      }
                                    }

                                    return true; // Include logs that pass all filters
                                  }).toList();

                                  // Update the filteredDocs
                                  filteredDocs = localFilteredDocs;

                                  if (startDate != null && endDate == null) {
                                    return Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(height: 10),
                                          Text(
                                            'Waiting for End date to be chosen...',
                                            style: TextStyle(color: Colors.orange, fontSize: 16),
                                          ),
                                          CircularProgressIndicator(),
                                        ],
                                      ),
                                    );
                                  }

                                  if (filteredDocs.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No income info found for the selected filter',
                                        style: TextStyle(color: Colors.red, fontSize: 16),
                                      ),
                                    );
                                  }

                                  return Table(
                                    border: TableBorder.all(),
                                    columnWidths: {
                                      0: FixedColumnWidth(120), // Adjusted width for Admin Name
                                      1: FixedColumnWidth(120), // Adjusted width for User Name
                                      2: FixedColumnWidth(80),  // Adjusted width for Amount
                                      3: FixedColumnWidth(100), // Adjusted width for Date
                                    },
                                    children: [
                                      TableRow(
                                        children: [
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Admin Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('User Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      ...filteredDocs.map((doc) {
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
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(doc['adminName'] ?? 'N/A'),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(doc['userName'] ?? 'N/A'),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text('${doc['amount'] ?? 0}'),
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
                                                  doc['scannedTime'] != null && doc['scannedTime'] is Timestamp
                                                      ? DateFormat('yyyy-MM-dd HH:mm:ss').format((doc['scannedTime'] as Timestamp).toDate())
                                                      : '',
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ],
                                  );
                                },
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
                                      backgroundColor: Colors.white, // Set button background to white
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16.0), // Rounded corners
                                      ),
                                      side: BorderSide(color: Colors.green), // Add a green border
                                      elevation: 0, // Remove button shadow
                                    ),
                              onPressed: () async {
                                print("Button pressed. Checking filteredDocs...");

                                if (filteredDocs.isNotEmpty) {
                                  print("Filtered Docs is not empty. Proceeding to generate report...");

                                  // Show a loading dialog while generating the report
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false, // Prevent dismissal
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Generating Report"),
                                        content: Row(
                                          children: [
                                            CircularProgressIndicator(), // Show a loading spinner
                                            SizedBox(width: 16),
                                            Expanded(child: Text("Please wait while the report is being generated...")),
                                          ],
                                        ),
                                      );
                                    },
                                  );

                                  // Generate the report
                                  String filePath = await generateIncomeReport(filteredDocs);

                                  // Close the loading dialog
                                  Navigator.of(context).pop();

                                  // Show a success dialog with the file location
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

                                      // Show an error dialog if there are no documents
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

                                    // Additional debug print to track the filteredDocs length
                                    print("Filtered Docs length: ${filteredDocs.length}");
                                  },


                                      child: Row(
                                      mainAxisSize: MainAxisSize.max, // Ensure the button adjusts to content size
                                      children: [
                                        Icon(Icons.edit_note_outlined, color: Colors.green), // Icon with green color
                                        SizedBox(width: 8), // Space between the icon and text
                                        Text(
                                          'Generate a Report',
                                          style: TextStyle(color: Colors.green), // Text color set to green
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
            top: 60, // Adjust this value to move the button down
            left: 16, // Horizontal position
            child: FloatingActionButton(
              mini: true, // Smaller back button
              backgroundColor: isDarkMode ? Colors.grey : Colors.green,
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Navigate back to the previous screen
              },
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}