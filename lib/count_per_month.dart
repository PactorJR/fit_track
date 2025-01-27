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
  String? selectedMonth = 'All';
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

    return months.indexOf(monthName) + 1;
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
    if (selectedYear != 'All') {
      if (documentYear != int.parse(selectedYear)) {
        return false;
      }
    }
    return true;
  }

  bool filterByMonth(DateTime documentDate, String selectedMonth) {
    if (selectedMonth == 'All') {
      return true;
    }
    int selectedMonthNumber = monthNameToNumber(selectedMonth);
    return documentDate.month == selectedMonthNumber;
  }

  bool applyFilters(DateTime documentDate) {
    bool isYearValid = filterByYear(documentDate, selectedYear ?? 'All');
    bool isMonthValid = filterByMonth(documentDate, selectedMonth ?? 'All');
    return isYearValid && isMonthValid;
  }


  @override
  Future<String> generateReport(List<DocumentSnapshot> filteredDocs) async {
    await _requestPermissions();

    String currentDateTime = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    String fitTrackPath = '/storage/emulated/0/FitTrack';
    String countMonthPath = '$fitTrackPath/CountMonth';


    final fitTrackFolder = Directory(fitTrackPath);
    if (!await fitTrackFolder.exists()) {
      await fitTrackFolder.create(recursive: true);
    }


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
      String month = DateFormat('yyyy-MM').format(logDate);
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
                                    Icon(Icons.filter_list, color: isDarkMode ? Colors.white : Colors.black,),
                                    SizedBox(width: 8),
                                    DropdownButton<String>(
                                      value: selectedMonth,
                                      hint: Text('Select Month', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black,)),
                                      icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white : Colors.black,),
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
                                          child: Text(value, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black,)),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 20),


                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: isDarkMode ? Colors.white : Colors.black,),
                                    SizedBox(width: 8),
                                    DropdownButton<String>(
                                      value: selectedYear,
                                      hint: Text('Select Year', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black,)),
                                      icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white : Colors.black,),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedYear = newValue;
                                        });
                                      },
                                      items: <String>[
                                        'All',
                                        '2023', '2024', '2025', '2026',
                                      ].map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black,)),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
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
                                        Timestamp scannedTime = doc['scannedTime'];
                                        DateTime documentDate = scannedTime.toDate();
                                        return applyFilters(documentDate);
                                      }).toList();


                                      filteredDocs = localFilteredDocs;

                                      if (filteredDocs.isEmpty) {
                                        return Center(child: Text('No logs matching the filter.'));
                                      }

                                      return Table(
                                        border: TableBorder.all(),
                                        columnWidths: {
                                          0: FixedColumnWidth(120),
                                          1: FixedColumnWidth(120),
                                          2: FixedColumnWidth(100),
                                          3: FixedColumnWidth(120),
                                        },
                                        children: [
                                          TableRow(
                                            children: [
                                              Container(height: 40, alignment: Alignment.center, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                              Container(height: 40, alignment: Alignment.center, child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                                              Container(height: 40, alignment: Alignment.center, child: Text('Month', style: TextStyle(fontWeight: FontWeight.bold))),
                                              Container(height: 40, alignment: Alignment.center, child: Text('User ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                            ],
                                          ),
                                          ...localFilteredDocs.map((doc) {
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
                                                Container(
                                                  height: 40,
                                                  alignment: Alignment.center,
                                                  child: Text(doc['scannedTime'] != null && doc['scannedTime'] is Timestamp
                                                      ? formatTimestamp(doc['scannedTime'])
                                                      : ''),
                                                ),
                                                Container(
                                                  height: 40,
                                                  alignment: Alignment.center,
                                                  child: Text(doc['scannedTime'] != null && doc['scannedTime'] is Timestamp
                                                      ? DateFormat('MMMM yyyy').format((doc['scannedTime'] as Timestamp).toDate())
                                                      : ''),
                                                ),
                                                Container(height: 40, alignment: Alignment.center, child: Text(doc['userID']?.toString() ?? '')),
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
                                        borderRadius: BorderRadius.circular(
                                            16.0),
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
                                                  Expanded(child: Text(
                                                      "Please wait while the report is being generated...")),
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

                                      children: [
                                        Icon(Icons.edit_note_outlined,
                                            color: Colors.green),

                                        SizedBox(width: 8),

                                        Text(
                                          'Generate a Report',
                                          style: TextStyle(color: Colors
                                              .green),
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