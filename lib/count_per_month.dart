import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class CountPerMonthPage extends StatefulWidget {
  final String? userId;

  CountPerMonthPage({this.userId});

  @override
  _CountPerMonthPageState createState() => _CountPerMonthPageState();
}

class _CountPerMonthPageState extends State<CountPerMonthPage> {
  String? selectedUserId;
  TextEditingController searchController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  String? selectedMonth = 'All'; // To hold the selected month for filtering
  bool hasDataForSelectedMonth = true;
  List<DocumentSnapshot> filteredDocs = [];

  bool seen = false;
  String seenValue = 'False';
  String? selectedYear;

  int monthNameToNumber(String monthName) {
    const months = <String>[
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];

    return months.indexOf(monthName) + 1; // Adds 1 because months are 1-indexed
  }

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

    if (selectedUserId != null && selectedUserId == userId) {
      FirebaseFirestore.instance
          .collection('loghistory')
          .doc(userId)
          .get()
          .then((docSnapshot) {
        if (docSnapshot.exists) {
          FirebaseFirestore.instance
              .collection('loghistory')
              .doc(userId)
              .update({'seen': true});
        } else {
          print("Document with ID $userId not found.");
        }
      }).catchError((error) {
        print("Error checking document: $error");
      });
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  bool filterByYear(DateTime documentDate, String selectedYear) {
    int documentYear = documentDate.year;

    // Apply year filter if selectedYear is not 'All'
    if (selectedYear != 'All') {
      if (documentYear != int.parse(selectedYear)) {
        return false; // Exclude logs from a different year
      }
    }

    return true; // Include the document if it passes the year filter
  }

  bool filterByMonth(DateTime documentDate, String selectedMonth) {
    if (selectedMonth == 'All') {
      return true; // No month filter applied if "All" is selected
    }

    int selectedMonthNumber = monthNameToNumber(selectedMonth);
    return documentDate.month == selectedMonthNumber; // Filter by selected month
  }

  bool applyFilters(DateTime documentDate) {
    // Apply the year filter
    bool isYearValid = filterByYear(documentDate, selectedYear ?? 'All');

    // Apply the month filter
    bool isMonthValid = filterByMonth(documentDate, selectedMonth ?? 'All');

    // Return true if both filters pass
    return isYearValid && isMonthValid;
  }


  @override
  Future<String> generateReport(List<DocumentSnapshot> filteredDocs) async {
    await _requestPermissions();

    String currentDateTime = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    String fitTrackPath = '/storage/emulated/0/FitTrack';
    String countMonthPath = '$fitTrackPath/CountMonth';

    // Create the FitTrack directory if it doesn't exist
    final fitTrackFolder = Directory(fitTrackPath);
    if (!await fitTrackFolder.exists()) {
      await fitTrackFolder.create(recursive: true);
    }

    // Create the CountMonth directory if it doesn't exist
    final countMonthFolder = Directory(countMonthPath);
    if (!await countMonthFolder.exists()) {
      await countMonthFolder.create(recursive: true);
    }

    String filePath = '$countMonthPath/report_$currentDateTime.txt';
    String reportContent = 'Users Information Report - $currentDateTime\n\n';
    reportContent += 'Name, Time, Month, User ID\n';

    Map<String, int> monthCounts = {};

    for (var doc in filteredDocs) {
      String name = '${doc['firstName']} ${doc['lastName'] ?? ''}';
      String time = doc['scannedTime'] != null && doc['scannedTime'] is Timestamp
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format((doc['scannedTime'] as Timestamp).toDate())
          : 'N/A';
      DateTime logDate = (doc['scannedTime'] as Timestamp).toDate();
      String month = DateFormat('yyyy-MM').format(logDate); // "yyyy-MM" format for month
      String userId = doc['userID']?.toString() ?? 'N/A';

      if (!monthCounts.containsKey(month)) {
        monthCounts[month] = 0;
      }
      monthCounts[month] = monthCounts[month]! + 1;

      reportContent += '$name, $time, $month, $userId\n';
    }

    reportContent += '\nSummary of Users per Month:\n';
    monthCounts.forEach((month, count) {
      reportContent += '$month: $count\n';
    });

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
                    'Monthly Reporting',
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
                                // Filter dropdown for month selection
                                Row(
                                  children: [
                                    Icon(Icons.filter_list, color: Colors.white),
                                    SizedBox(width: 8),
                                    DropdownButton<String>(
                                      value: selectedMonth,
                                      hint: Text('Select Month', style: TextStyle(color: Colors.white)),
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedMonth = newValue;
                                        });
                                      },
                                      items: <String>[
                                        'All',
                                        'January', 'February', 'March', 'April', 'May', 'June',
                                        'July', 'August', 'September', 'October', 'November', 'December'
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

                                // Filter dropdown for year selection
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Colors.white),
                                    SizedBox(width: 8),
                                    DropdownButton<String>(
                                      value: selectedYear,
                                      hint: Text('Select Year', style: TextStyle(color: Colors.white)),
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedYear = newValue;
                                        });
                                      },
                                      items: <String>[
                                        'All',
                                        '2023', '2024', '2025', '2026', // Add more years as needed
                                      ].map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value, style: TextStyle(color: Colors.black)),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('loghistory')
                                    .where('type', isEqualTo: 'login') // Filter for type: "login"
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Center(child: Text('Error: ${snapshot.error}'));
                                  }
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return Center(child: Text('No users found.'));
                                  }

                                  // Local filtering for year and month
                                  List<DocumentSnapshot> localFilteredDocs = snapshot.data!.docs.where((doc) {
                                    // Check if scannedTime exists and is a Timestamp
                                    if (doc['scannedTime'] == null || !(doc['scannedTime'] is Timestamp)) {
                                      return false;
                                    }

                                    // Check if 'type' exists and is a String
                                    if (doc['type'] == null || !(doc['type'] is String)) {
                                      return false;
                                    }

                                    DateTime scannedDateTime = (doc['scannedTime'] as Timestamp).toDate();

                                    // Apply year filter
                                    if (!filterByYear(scannedDateTime, selectedYear ?? 'All')) {
                                      return false;
                                    }

                                    // Apply month filter
                                    if (selectedMonth != 'All' && !filterByMonth(scannedDateTime, selectedMonth ?? '')) {
                                      return false;
                                    }

                                    return true;
                                  }).toList();

                                  if (filteredDocs != localFilteredDocs) {
                                    filteredDocs = localFilteredDocs;
                                  }

                                  bool hasDataForSelectedMonthAndYear = filteredDocs.isNotEmpty;

                                  if (!hasDataForSelectedMonthAndYear) {
                                    return Center(
                                      child: Text(
                                        'No user found for the selected Month/Year',
                                        style: TextStyle(color: Colors.red, fontSize: 14),
                                      ),
                                    );
                                  }

                                  return Table(
                                    border: TableBorder.all(),
                                    columnWidths: {
                                      0: FixedColumnWidth(100),
                                      1: FixedColumnWidth(100),
                                      2: FixedColumnWidth(80),
                                      3: FixedColumnWidth(100),
                                    },
                                    children: [
                                      TableRow(
                                        children: [
                                          Container(height: 40,
                                              alignment: Alignment.center,
                                              child: Text('Name',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight
                                                          .bold))),
                                          Container(height: 40,
                                              alignment: Alignment.center,
                                              child: Text('Time',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight
                                                          .bold))),
                                          Container(height: 40,
                                              alignment: Alignment.center,
                                              child: Text('Month',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight
                                                          .bold))),
                                          Container(height: 40,
                                              alignment: Alignment.center,
                                              child: Text('User ID',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight
                                                          .bold))),
                                        ],
                                      ),
                                      ...filteredDocs.map((doc) {
                                        return TableRow(
                                          decoration: BoxDecoration(
                                            color: selectedUserId == doc.id
                                                ? Colors.white.withOpacity(0.8)
                                                : Colors.transparent,
                                          ),
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);
                                                FirebaseFirestore.instance
                                                    .collection('loghistory')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(height: 40,
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                      '${doc['firstName']} ${doc['lastName'] ??
                                                          ''}')),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                    doc['scannedTime'] !=
                                                        null &&
                                                        doc['scannedTime'] is Timestamp
                                                        ? DateFormat(
                                                        'yyyy-MM-dd HH:mm:ss')
                                                        .format(
                                                        (doc['scannedTime'] as Timestamp)
                                                            .toDate())
                                                        : ''),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);
                                              },
                                              child: Container(height: 40,
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                      doc['scannedTime'] !=
                                                          null &&
                                                          doc['scannedTime'] is Timestamp
                                                          ? DateFormat(
                                                          'MMMM yyyy').format(
                                                          (doc['scannedTime'] as Timestamp)
                                                              .toDate())
                                                          : '')),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);
                                              },
                                              child: Container(height: 40,
                                                  alignment: Alignment.center,
                                                  child: Text(doc['userID']
                                                      ?.toString() ?? '')),
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
                                      backgroundColor: Colors.white,
                                      // Set button background to white
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            16.0), // Rounded corners
                                      ),
                                      side: BorderSide(color: Colors.green),
                                      // Add a green border
                                      elevation: 0, // Remove button shadow
                                    ),
                                    onPressed: () async {
                                      if (filteredDocs.isNotEmpty) {
                                        // Show a loading dialog while generating the report
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          // Prevent dismissal
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text("Generating Report"),
                                              content: Row(
                                                children: [
                                                  CircularProgressIndicator(),
                                                  // Show a loading spinner
                                                  SizedBox(width: 16),
                                                  Expanded(child: Text(
                                                      "Please wait while the report is being generated...")),
                                                ],
                                              ),
                                            );
                                          },
                                        );

                                        // Generate the report
                                        String filePath = await generateReport(
                                            filteredDocs);

                                        // Close the loading dialog
                                        Navigator.of(context).pop();

                                        // Show a success dialog with the file location
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text("Report Generated"),
                                              content: Text(
                                                  "The report has been successfully generated.\n\nLocation:\n$filePath"),
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
                                        // Show an error dialog if there are no documents
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text("No Data"),
                                              content: Text(
                                                  "No data available to generate the report."),
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
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      // Ensure the button adjusts to content size
                                      children: [
                                        Icon(Icons.edit_note_outlined,
                                            color: Colors.green),
                                        // Icon with green color
                                        SizedBox(width: 8),
                                        // Space between the icon and text
                                        Text(
                                          'Generate a Report',
                                          style: TextStyle(color: Colors
                                              .green), // Text color set to green
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