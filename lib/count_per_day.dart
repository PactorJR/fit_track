import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

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
  DateTime? endDate;
  String? selectedDay;
  bool hasDataForSelectedDay = true;
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
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

  bool filterByDay(String documentDay, Timestamp scannedTime, String documentType) {
    DateTime logDate = scannedTime.toDate();

    if (selectedDay != null && selectedDay!.toLowerCase() == "all") {
      return documentType.toLowerCase() == "login";
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

    if (selectedDay != null && selectedDay!.isNotEmpty) {
      return documentDay.toLowerCase() == selectedDay!.toLowerCase();
    }

    return true;
  }

  @override
  Future<String> generateReport(List<DocumentSnapshot> filteredDocs) async {
    await _requestPermissions();

    String currentDateTime = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

    String fitTrackPath = '/storage/emulated/0/FitTrack';
    String countDayPath = '$fitTrackPath/CountDay';

    final fitTrackFolder = Directory(fitTrackPath);
    if (!await fitTrackFolder.exists()) {
      await fitTrackFolder.create(recursive: true);
    }

    final countDayFolder = Directory(countDayPath);
    if (!await countDayFolder.exists()) {
      await countDayFolder.create(recursive: true);
    }

    String filePath = '$countDayPath/report_$currentDateTime.txt';

    String reportContent = 'Users Information Report - $currentDateTime\n\n';
    reportContent += 'Name, Time, Day, User ID\n';

    Map<String, int> dayCounts = {};

    for (var doc in filteredDocs) {
      String name = '${doc['firstName']} ${doc['lastName'] ?? ''}';
      String time = doc['scannedTime'] != null && doc['scannedTime'] is Timestamp
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format((doc['scannedTime'] as Timestamp).toDate())
          : 'N/A';
      String day = doc['day'] ?? 'Unknown';
      String userId = doc['userID']?.toString() ?? 'N/A';

      if (!dayCounts.containsKey(day)) {
        dayCounts[day] = 0;
      }
      dayCounts[day] = dayCounts[day]! + 1;

      reportContent += '$name, $time, $day, $userId\n';
    }

    reportContent += '\nSummary of Users per Day:\n';
    dayCounts.forEach((day, count) {
      reportContent += '$day: $count\n';
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
    Orientation orientation = MediaQuery.of(context).orientation;


    double containerWidth = orientation == Orientation.portrait
        ? 600
        : 1000;
    double tableWidth = orientation == Orientation.portrait
        ? 100
        : 200;
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
            Padding(
            padding: const EdgeInsets.only(top: 100),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
    child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 800),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: containerWidth,
                      height: 600,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black38 : Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: Colors.green,
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
                                    Icon(Icons.filter_list, color: Colors.white),
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
                                        startDate == null
                                            ? 'Start'
                                            : DateFormat('MM-dd').format(startDate!),
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                          fontSize: 16,
                                        ),
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
                                        endDate == null
                                            ? 'End'
                                            : DateFormat('MM-dd').format(endDate!),
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                          fontSize: 16,
                                        ),
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
                                stream: FirebaseFirestore.instance
                                    .collection('loghistory')
                                    .where('type', isEqualTo: 'login')
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


                                  List<DocumentSnapshot> localFilteredDocs = snapshot.data!.docs.where((doc) {
                                    if (doc['scannedTime'] == null || !(doc['scannedTime'] is Timestamp)) {
                                      return false;
                                    }
                                    if (doc['type'] == null || doc['type'] is! String) {
                                      return false;
                                    }
                                    return filterByDay(
                                      doc['day'] ?? '',
                                      doc['scannedTime'] as Timestamp,
                                      doc['type'] as String,
                                    );
                                  }).toList();



                                  if (filteredDocs != localFilteredDocs) {
                                    filteredDocs = localFilteredDocs;
                                  }

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
                                      0: FixedColumnWidth(tableWidth),
                                      1: FixedColumnWidth(tableWidth),
                                      2: FixedColumnWidth(80),
                                      3: FixedColumnWidth(tableWidth),
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
                                      if (filteredDocs.isNotEmpty) {

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


                                        String filePath = await generateReport(filteredDocs);


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