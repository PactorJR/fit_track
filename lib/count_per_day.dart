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

class CountPerDayPage extends StatefulWidget {
  final String? userId;

  CountPerDayPage({this.userId});

  @override
  _CountPerDayPageState createState() => _CountPerDayPageState();
}

class _CountPerDayPageState extends State<CountPerDayPage> {
  String? selectedUserId;
  TextEditingController searchController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate; // Store the selected date
  String? selectedDay; // To hold the selected day for filtering
  bool hasDataForSelectedDay = true; // Add this to your state
  List<DocumentSnapshot> filteredDocs = [];

  bool seen = false;
  String seenValue = 'False';

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

  bool filterByDay(String documentDay, Timestamp scannedTime, String documentType) {
    DateTime logDate = scannedTime.toDate();

    // Check if the selectedDay is "All"
    if (selectedDay != null && selectedDay!.toLowerCase() == "all") {
      // Show only documents with the field "type" equal to "login"
      return documentType.toLowerCase() == "login";
    }

    // Check if the startDate is chosen but the endDate is not selected
    if (startDate != null && endDate == null) {
      // Display message or handle the logic accordingly
      print("Waiting for End date to be chosen...");
      return false; // Optionally, you could return false to not display any logs during this period
    }

    // Filter by date range: Only show logs within the range
    if (startDate != null && endDate != null) {
      bool withinRange = !logDate.isBefore(startDate!) && !logDate.isAfter(endDate!);
      if (!withinRange) {
        return false; // Exclude logs outside the date range
      }
    }

    // If no date range filter is applied, fallback to filtering by specific day
    if (selectedDay != null && selectedDay!.isNotEmpty) {
      return documentDay.toLowerCase() == selectedDay!.toLowerCase();
    }

    // Default: Show all if no filters are applied
    return true;
  }


  @override
  Future<String> generateReport(List<DocumentSnapshot> filteredDocs) async {
    // Request permissions for storage
    await _requestPermissions();

    // Get the current date and time for the file name
    String currentDateTime = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

    // Define the path to external storage (e.g., "/storage/emulated/0/FitTrack/CountDay")
    String fitTrackPath = '/storage/emulated/0/FitTrack';
    String countDayPath = '$fitTrackPath/CountDay';

    // Create the FitTrack directory if it doesn't exist
    final fitTrackFolder = Directory(fitTrackPath);
    if (!await fitTrackFolder.exists()) {
      await fitTrackFolder.create(recursive: true);
    }

    // Create the CountDay directory if it doesn't exist
    final countDayFolder = Directory(countDayPath);
    if (!await countDayFolder.exists()) {
      await countDayFolder.create(recursive: true);
    }

    // Define the file path inside the CountDay folder with the current date and time
    String filePath = '$countDayPath/report_$currentDateTime.txt';

    // Initialize a list to store the content for the report (name, time, day, userId)
    String reportContent = 'Users Information Report - $currentDateTime\n\n';
    reportContent += 'Name, Time, Day, User ID\n';

    // Map to count users for each day
    Map<String, int> dayCounts = {};

    // Loop through filteredDocs to build the report
    for (var doc in filteredDocs) {
      String name = '${doc['firstName']} ${doc['lastName'] ?? ''}';
      String time = doc['scannedTime'] != null && doc['scannedTime'] is Timestamp
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format((doc['scannedTime'] as Timestamp).toDate())
          : 'N/A';
      String day = doc['day'] ?? 'Unknown';
      String userId = doc['userID']?.toString() ?? 'N/A';

      // Increment the count for the day
      if (!dayCounts.containsKey(day)) {
        dayCounts[day] = 0;
      }
      dayCounts[day] = dayCounts[day]! + 1;

      // Add the row data for each document
      reportContent += '$name, $time, $day, $userId\n';
    }

    // Add a summary section for user counts per day
    reportContent += '\nSummary of Users per Day:\n';
    dayCounts.forEach((day, count) {
      reportContent += '$day: $count\n';
    });

    // Create the file and write the report content
    File file = File(filePath);
    await file.writeAsString(reportContent);

    // Return the file path after saving the report
    return filePath;
  }

  Future<void> _requestPermissions() async {
    // Request permission to access storage
    if (await Permission.manageExternalStorage.request().isGranted) {
      // Permission granted
      print("Storage permission granted");
    } else {
      // Permission denied
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
                    'Day Reporting',
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
                                // Filter dropdown with icon on the left
                                Row(
                                  children: [
                                    Icon(Icons.filter_list, color: Colors.white), // Filter icon
                                    SizedBox(width: 8), // Space between the icon and dropdown
                                    DropdownButton<String>(
                                      value: selectedDay,
                                      hint: Text('Select Day', style: TextStyle(color: Colors.white)),
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.white), // Dropdown arrow
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedDay = newValue;
                                        });
                                      },
                                      items: <String>[
                                        'All', // Add "All" option here
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
                                SizedBox(width: 20), // Space between dropdown and next element
                                GestureDetector(
                                  onTap: () async {
                                    DateTime? pickedDate = await _selectDate(context, initialDate: startDate);  // Pass startDate as the initial date
                                    if (pickedDate != null) {
                                      setState(() {
                                        startDate = pickedDate; // Update only the start date
                                      });
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        startDate == null
                                            ? 'Start'
                                            : DateFormat('MM-dd').format(startDate!), // Display selected start date
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(width: 20),

                                GestureDetector(
                                  onTap: () async {
                                    DateTime? pickedDate = await _selectDate(context, initialDate: endDate);  // Pass endDate as the initial date
                                    if (pickedDate != null) {
                                      setState(() {
                                        endDate = pickedDate; // Update only the end date
                                      });
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        endDate == null
                                            ? 'End'
                                            : DateFormat('MM-dd').format(endDate!), // Display selected end date
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8), // Space after the end date
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

                                  // Compute filteredDocs based on the current filter criteria
                                  List<DocumentSnapshot> localFilteredDocs = snapshot.data!.docs.where((doc) {
                                    if (doc['scannedTime'] == null || !(doc['scannedTime'] is Timestamp)) {
                                      return false;
                                    }
                                    if (doc['type'] == null || doc['type'] is! String) {
                                      return false; // Ensure the "type" field exists and is a String
                                    }
                                    return filterByDay(
                                      doc['day'] ?? '',                   // documentDay
                                      doc['scannedTime'] as Timestamp,    // scannedTime
                                      doc['type'] as String,              // documentType
                                    );
                                  }).toList();


                                  // Update the filteredDocs only if the localFilteredDocs has changed
                                  if (filteredDocs != localFilteredDocs) {
                                    filteredDocs = localFilteredDocs; // Update state only when necessary
                                  }

                                  // Check if there are documents for the selected day
                                  bool hasDataForSelectedDay = filteredDocs.isNotEmpty;

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

                                  if (!hasDataForSelectedDay) {
                                    return Center(
                                      child: Text(
                                        'No user info found for that day',
                                        style: TextStyle(color: Colors.red, fontSize: 16),
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
                                          Container(height: 40, alignment: Alignment.center, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                          Container(height: 40, alignment: Alignment.center, child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                                          Container(height: 40, alignment: Alignment.center, child: Text('Day', style: TextStyle(fontWeight: FontWeight.bold))),
                                          Container(height: 40, alignment: Alignment.center, child: Text('User ID', style: TextStyle(fontWeight: FontWeight.bold))),
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
                                                FirebaseFirestore.instance.collection('loghistory').doc(doc.id).update({'seen': true});
                                              },
                                              child: Container(height: 40, alignment: Alignment.center, child: Text('${doc['firstName']} ${doc['lastName'] ?? ''}')),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(doc['scannedTime'] != null && doc['scannedTime'] is Timestamp
                                                    ? DateFormat('yyyy-MM-dd HH:mm:ss').format((doc['scannedTime'] as Timestamp).toDate())
                                                    : ''),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);
                                              },
                                              child: Container(height: 40, alignment: Alignment.center, child: Text(doc['day']?.toString() ?? '')),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);
                                              },
                                              child: Container(height: 40, alignment: Alignment.center, child: Text(doc['userID']?.toString() ?? '')),
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
                                      if (filteredDocs.isNotEmpty) {
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
                                        String filePath = await generateReport(filteredDocs);

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