import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'count_per_day.dart';
import 'count_per_month.dart';
import 'users_admin.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'income_admin.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

class GraphsAdminPage extends StatefulWidget {
  const GraphsAdminPage({Key? key}) : super(key: key);

  @override
  _GraphsAdminPageState createState() => _GraphsAdminPageState();
}

class _GraphsAdminPageState extends State<GraphsAdminPage> {
  List<int> dailyCounts = List.filled(7, 0);
  List<int> monthlyCounts = List.filled(12, 0);
  int totalIncome = 0;
  int activeUsersCount = 0;
  int totalUsersCount = 0;
  int bannedUsersCount = 0;
  Map<int, int> monthlyIncome = {};
  List<DocumentSnapshot> filteredDocs = [];
  bool _isLoading = true;
  bool hasIncomeData = false;

  @override
  void initState() {
    super.initState();
    hasIncomeData = false;
    fetchLoginCounts();
    fetchTotalIncome();
    fetchMonthlyIncome();
    fetchBannedUsersCount();
    fetchActiveUsersCount();
    fetchUserCounts();
    getDailyCounts().then((counts) {
      setState(() {
        dailyCounts = counts;
      });
    }).catchError((e) {
      print("Error fetching data: $e");
    });
  }

  Future<void> fetchLoginCounts({int? filterYear, int? filterMonth}) async {
    List<int> counts = List.filled(12, 0);

    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('loghistory').get();

    for (var doc in snapshot.docs) {
      if (doc['type'] == 'login' && doc['scannedTime'] is Timestamp) {
        DateTime loginTime = (doc['scannedTime'] as Timestamp).toDate();

        if (filterYear != null && filterMonth != null) {
          if (loginTime.year != filterYear || loginTime.month != filterMonth) {
            continue;
          }
        }

        counts[loginTime.month - 1]++;
      }
    }

    setState(() {
      monthlyCounts = counts;
    });
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        fetchLoginCounts(),
        fetchTotalIncome(),
        fetchMonthlyIncome(),
        fetchBannedUsersCount(),
        fetchActiveUsersCount(),
        fetchUserCounts(),
        getDailyCounts().then((counts) {
          dailyCounts = counts;
        }),
      ]);
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetchAllData();
  }

  Future<void> fetchData() async {
    await fetchActiveUsersCount();
    await fetchBannedUsersCount();
    await fetchUserCounts();
    await fetchTotalIncome();
    await fetchMonthlyIncome();
    await fetchLoginCounts();

    filteredDocs = await FirebaseFirestore.instance
        .collection('users')
        .where('userStatus', isEqualTo: 'Active')
        .get()
        .then((snapshot) => snapshot.docs);

    await generateReport(filteredDocs);
  }

  String formatDateTime(DateTime dateTime) {
    String year = dateTime.year.toString();
    String month = dateTime.month.toString().padLeft(2, '0');
    String day = dateTime.day.toString().padLeft(2, '0');
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String second = dateTime.second.toString().padLeft(2, '0');

    return '$year-$month-$day-$hour-$minute-$second';
  }

  Future<void> fetchActiveUsersCount() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userStatus', isEqualTo: 'Active')
          .get();

      setState(() {
        activeUsersCount = snapshot.docs.length;
      });
    } catch (e) {
      print("Error fetching active users count: $e");
    }
  }

  Future<void> fetchUserCounts() async {
    try {
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      setState(() {
        totalUsersCount = usersSnapshot.docs.length;
      });
    } catch (e) {
      print("Error fetching total users count: $e");
    }
  }

  Future<void> fetchBannedUsersCount() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userStatus', isEqualTo: 'Banned')
          .get();

      setState(() {
        bannedUsersCount = snapshot.docs.length;
      });
    } catch (e) {
      print("Error fetching banned users count: $e");
    }
  }

  Future<void> fetchTotalIncome({int? filterYear, int? filterMonth}) async {
    totalIncome = 0;
    hasIncomeData = false;

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('cashinlogs').get();
    QuerySnapshot guestsSnapshot = await FirebaseFirestore.instance.collection('guests').get();

    for (var doc in snapshot.docs) {
      DateTime scannedDate = (doc['scannedTime'] as Timestamp).toDate();

      if (filterYear != null && filterMonth != null) {
        if (scannedDate.year != filterYear || scannedDate.month != filterMonth) {
          continue;
        }
      }

      var amount = doc['amount'];
      if (amount is int) {
        totalIncome += amount;
      } else if (amount is double) {
        totalIncome += amount.toInt();
      }
    }

    for (var guestDoc in guestsSnapshot.docs) {
      DateTime guestDate = (guestDoc['timeStamp'] as Timestamp).toDate();

      if (filterYear != null && filterMonth != null) {
        if (guestDate.year != filterYear || guestDate.month != filterMonth) {
          continue;
        }
      }

      var amountPaid = guestDoc['amountPaid'];
      if (amountPaid is int) {
        totalIncome += amountPaid;
      } else if (amountPaid is double) {
        totalIncome += amountPaid.toInt();
      }
    }

    if (totalIncome == 0) {
      hasIncomeData = false;
    } else {
      hasIncomeData = true;
    }

    setState(() {});
  }

  Future<void> fetchMonthlyIncome({int? filterYear, int? filterMonth}) async {
    Map<int, int> incomeByMonth = {};
    hasIncomeData = false;

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('cashinlogs').get();
    QuerySnapshot guestsSnapshot = await FirebaseFirestore.instance.collection('guests').get();

    for (var doc in snapshot.docs) {
      DateTime scannedDate = (doc['scannedTime'] as Timestamp).toDate();
      int month = scannedDate.month;
      int amount = doc['amount'] ?? 0;

      if (filterYear != null && filterMonth != null) {
        if (scannedDate.year != filterYear || scannedDate.month != filterMonth) {
          continue;
        }
      }

      if (incomeByMonth.containsKey(month)) {
        incomeByMonth[month] = incomeByMonth[month]! + amount;
      } else {
        incomeByMonth[month] = amount;
      }
    }

    for (var guestDoc in guestsSnapshot.docs) {
      DateTime guestDate = (guestDoc['timeStamp'] as Timestamp).toDate();
      int month = guestDate.month;
      int amountPaid = guestDoc['amountPaid'] ?? 0;

      if (filterYear != null && filterMonth != null) {
        if (guestDate.year != filterYear || guestDate.month != filterMonth) {
          continue;
        }
      }

      if (incomeByMonth.containsKey(month)) {
        incomeByMonth[month] = incomeByMonth[month]! + amountPaid;
      } else {
        incomeByMonth[month] = amountPaid;
      }
    }

    if (incomeByMonth.isEmpty) {
      totalIncome = 0;
      hasIncomeData = false;
      setState(() {
        monthlyIncome = {};
      });
      return;
    }

    totalIncome = incomeByMonth.values.reduce((a, b) => a + b);
    hasIncomeData = true;

    setState(() {
      monthlyIncome = incomeByMonth;
    });
  }

  Future<void> generateReport(List<DocumentSnapshot> filteredDocs) async {
    try {
      String report = 'User Report\n';
      report += '==========================\n';

      int totalUsersCount = 0;
      int activeUsersCount = 0;
      int bannedUsersCount = 0;
      double totalIncome = 0;
      List<int> dailyCounts = List.filled(7, 0);
      List<double?> monthlyIncome = List.filled(12, 0);

      for (var doc in filteredDocs) {
        totalUsersCount++;
        if (doc['userStatus'] == 'Active') {
          activeUsersCount++;
        } else if (doc['userStatus'] == 'Banned') {
          bannedUsersCount++;
        }
        totalIncome += doc['wallet'] ?? 0;

        var lastLogin = doc['lastLogin'];
        String loginDateString = lastLogin is String ? lastLogin : '';

        DateTime? loginDate;
        if (loginDateString == "N/A") {
          loginDate = null;
        } else if (lastLogin is Timestamp) {
          loginDate = lastLogin.toDate();
        } else if (loginDateString.isNotEmpty) {
          try {
            loginDate = DateTime.parse(loginDateString);
          } catch (e) {
            print('Invalid date format for lastLogin: $lastLogin');
            loginDate = DateTime.now();
          }
        } else {
          print('Invalid lastLogin data: $lastLogin');
          loginDate = DateTime.now();
        }

        String loginDateDisplay = loginDate == null ? "N/A" : loginDate.toString();

        int dayOfWeek = loginDate?.weekday ?? 0;
        if (dayOfWeek > 0) {
          dailyCounts[dayOfWeek % 7]++;
        }

        int month = loginDate?.month ?? 0;
        if (month > 0) {
          monthlyIncome[month - 1] = (monthlyIncome[month - 1] ?? 0) + (doc['wallet'] ?? 0);
        }

        String userId = doc['userID'] ?? 'Unknown';

        report += "User: $userId 's Last Login: $loginDateDisplay\n";
      }

      report += 'Total Users: $totalUsersCount\n';
      report += 'Active Users: $activeUsersCount\n';
      report += 'Banned Users: $bannedUsersCount\n';
      report += 'Total Income: \$${totalIncome.toString()}\n';

      report += '\nDaily Login Counts (Sun-Sat):\n';
      report += '----------------------------\n';
      List<String> daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      for (int i = 0; i < 7; i++) {
        report += '${daysOfWeek[i]}: ${dailyCounts[i]} logins\n';
      }

      report += '\nMonthly Income:\n';
      report += '----------------\n';
      for (int i = 0; i < 12; i++) {
        String monthName = DateTime(2024, i + 1).toString().substring(5, 7);
        report += '$monthName: \$${monthlyIncome[i] ?? 0}\n';
      }

      String currentDateTime = formatDateTime(DateTime.now());

      String fitTrackPath = '/storage/emulated/0/FitTrack';

      final fitTrackFolder = Directory(fitTrackPath);
      if (!await fitTrackFolder.exists()) {
        await fitTrackFolder.create(recursive: true);
      }

      final generalReportsFolder = Directory('$fitTrackPath/General Reports');
      if (!await generalReportsFolder.exists()) {
        await generalReportsFolder.create(recursive: true);
      }

      String filePath = '$fitTrackPath/General Reports/GeneralReport_$currentDateTime.txt';

      final file = File(filePath);
      await file.writeAsString(report);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report generated at $filePath')));
    } catch (e) {
      print('Error generating report: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating report')));
    }
    await _requestPermissions();
  }

  void triggerReportGeneration() async {
    await fetchData();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      print("Storage permission granted");
    } else {
      print("Storage permission denied");
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isDarkMode
                      ? 'assets/images/dark_bg.png'
                      : 'assets/images/bg.png',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_note_outlined,
                  size: 24,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.green,
                ),
                Text(
                  'Reports',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Positioned(
            top: 20,
            left: 16,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey
                    : Colors.green,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CountPerDayPage(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black38
                              : Colors.white,
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Count per Day',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.light
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                CustomPaint(
                                  size: Size(MediaQuery.of(context).size.width, 40),
                                  painter: DayHeatmapPainter(
                                    isDarkMode: Theme.of(context).brightness == Brightness.dark,
                                    dailyCounts: dailyCounts,
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: ElevatedButton(
                                onPressed: () async {
                                  DateTime now = DateTime.now();
                                  DateTime firstDayOfThisMonth = DateTime(now.year, now.month, 1);
                                  DateTime lastDayOfLastMonth = firstDayOfThisMonth.subtract(const Duration(days: 1));
                                  DateTime firstDayOfLastMonth = DateTime(lastDayOfLastMonth.year, lastDayOfLastMonth.month, 1);

                                  DateTimeRange? pickedRange = await showDateRangePicker(
                                    context: context,
                                    initialDateRange: DateTimeRange(
                                      start: firstDayOfLastMonth,
                                      end: lastDayOfLastMonth,
                                    ),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                  );

                                  if (pickedRange != null) {
                                    List<int> filteredCounts = await getDailyCounts(
                                      startDate: pickedRange.start,
                                      endDate: pickedRange.end,
                                    );

                                    setState(() {
                                      dailyCounts = filteredCounts;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(6),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CountPerMonthPage(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black38
                              : Colors.white,
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await showYearMonthPicker(
                                        context,
                                            (selectedYear, selectedMonth) async {
                                          await fetchLoginCounts(
                                            filterYear: selectedYear,
                                            filterMonth: selectedMonth,
                                          );

                                          setState(() {
                                            monthlyCounts = List.from(monthlyCounts);
                                          });
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(6),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 30),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Count per Month',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.light
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 0),
                                      CustomPaint(
                                        size: Size(MediaQuery.of(context).size.width, 80),
                                        painter: MonthGraphPainter(
                                          isDarkMode: isDarkMode,
                                          monthlyCounts: monthlyCounts,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IncomeAdminPage(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black38
                              : Colors.white,
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await showYearMonthPickerIncome(
                                        context,
                                            (selectedYear, selectedMonth) async {
                                          await fetchTotalIncome(
                                            filterYear: selectedYear,
                                            filterMonth: selectedMonth,
                                          );
                                          await fetchMonthlyIncome(
                                            filterYear: selectedYear,
                                            filterMonth: selectedMonth,
                                          );

                                          setState(() {
                                            monthlyCounts = List.from(monthlyCounts);
                                          });
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(6),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 30),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Monthly Income',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.light
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        width: MediaQuery.of(context).size.width,
                                        height: 80,
                                        child: (!hasIncomeData)
                                            ? Center(
                                          child: Text(
                                            'No income in that selected year and date',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Theme.of(context).brightness == Brightness.light
                                                  ? Colors.black
                                                  : Colors.white,
                                            ),
                                          ),
                                        )
                                            : CustomPaint(
                                          size: Size(MediaQuery.of(context).size.width, 80),
                                          painter: IncomeBarPainter(
                                            isDarkMode: isDarkMode,
                                            totalIncome,
                                            monthlyIncome,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UsersAdminPage(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black38
                              : Colors.white,
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Users Chart',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            CustomPaint(
                              size: Size(MediaQuery.of(context).size.width, 80),
                              painter: ActiveUsersPainter(
                                activeUsersCount,
                                bannedUsersCount,
                                totalUsersCount,
                              ),
                            ),
                            const SizedBox(height: 25),
                            Builder(
                              builder: (context) {
                                double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
                                double screenWidth = MediaQuery.of(context).size.width;

                                double fontSize = (screenWidth <= 320 || devicePixelRatio < 2.0) ? 10.0 : 12.0;
                                double paddingVertical = (screenWidth <= 320 || devicePixelRatio < 2.0) ? 4.0 : 6.0;
                                double paddingHorizontal = (screenWidth <= 320 || devicePixelRatio < 2.0) ? 2.0 : 4.0;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: paddingHorizontal),
                                      decoration: BoxDecoration(
                                        color: Colors.yellow,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'On Approval Users',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: fontSize,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: paddingHorizontal),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Banned Users',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: fontSize,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: paddingHorizontal),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Active Users',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: fontSize,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          await fetchData();

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

                            await generateReport(filteredDocs);

                            Navigator.of(context).pop();

                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Report Generated"),
                                  content: Text("The report has been successfully generated."),
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
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(MediaQuery.of(context).size.width - 32, 50),
                          backgroundColor: isDarkMode ? Colors.grey : Colors.green,
                        ),
                        child: Text(
                          'Generate General Reports',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
              ),
            ),
          ),
      ),
    ],
      ),
    );
  }
}

class MonthGraphPainter extends CustomPainter {
  final bool isDarkMode;
  final List<int> monthlyCounts;

  MonthGraphPainter({required this.isDarkMode, required this.monthlyCounts});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()..color = isDarkMode ? Colors.white : Colors.black..strokeWidth = 1;
    final Paint linePaint = Paint()..color = Colors.green..strokeWidth = 2;
    final TextStyle labelStyle = TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 12);

    double columnWidth = size.width / 12;
    double rowHeight = size.height / 3;

    List<String> monthsOfYear = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (int i = 0; i < 3; i++) {
      canvas.drawLine(Offset(15, i * rowHeight), Offset(size.width, i * rowHeight), gridPaint);
      final labelValue = (30 - (i * 10));
      final textPainter = TextPainter(
        text: TextSpan(text: '$labelValue', style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-5, i * rowHeight - 6));
    }

    for (int i = 0; i < 12; i++) {
      final monthLabel = TextPainter(
        text: TextSpan(text: monthsOfYear[i], style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      monthLabel.layout();
      monthLabel.paint(canvas, Offset(i * columnWidth + columnWidth / 4, size.height + 5));
    }

    for (int month = 0; month < monthlyCounts.length - 1; month++) {
      final normalizedValueStart = (monthlyCounts[month] / 10).clamp(0, 30);
      final normalizedValueEnd = (monthlyCounts[month + 1] / 10).clamp(0, 30);

      final startPoint = Offset(
        month * columnWidth + columnWidth / 2,
        size.height - normalizedValueStart * rowHeight / 5,
      );
      final endPoint = Offset(
        (month + 1) * columnWidth + columnWidth / 2,
        size.height - normalizedValueEnd * rowHeight / 5,
      );

      canvas.drawLine(startPoint, endPoint, linePaint);
    }

    for (int month = 0; month < monthlyCounts.length; month++) {
      final countText = '${monthlyCounts[month]}';
      final countPainter = TextPainter(
        text: TextSpan(text: countText, style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      countPainter.layout();

      countPainter.paint(
        canvas,
        Offset(month * columnWidth + columnWidth / 2 - countPainter.width / 2,
            size.height - (monthlyCounts[month] / 10).clamp(0, 30) * rowHeight / 5 - 15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is MonthGraphPainter && oldDelegate.monthlyCounts != monthlyCounts;
  }
}

String _getMonthName(int index) {
  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return monthNames[index];
}

Future<void> showYearMonthPicker(
    BuildContext context,
    Function(int year, int month) onSelected,
    ) async {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

  bool isDarkMode = themeProvider.isDarkMode;

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      final dialogThemeProvider = Provider.of<ThemeProvider>(dialogContext);
      bool dialogIsDarkMode = dialogThemeProvider.isDarkMode;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: dialogIsDarkMode ? Colors.grey[900] : Colors.white,
            title: Text(
              'Select Year and Month',
              style: TextStyle(
                color: dialogIsDarkMode ? Colors.white : Colors.black,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Year:',
                      style: TextStyle(
                        color: dialogIsDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    DropdownButton<int>(
                      value: selectedYear,
                      dropdownColor:
                      dialogIsDarkMode ? Colors.grey[800] : Colors.white,
                      items: List.generate(
                        50,
                            (index) {
                          int year = DateTime.now().year - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: TextStyle(
                                color: dialogIsDarkMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedYear = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Month:',
                      style: TextStyle(
                        color: dialogIsDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    DropdownButton<int>(
                      value: selectedMonth,
                      dropdownColor:
                      dialogIsDarkMode ? Colors.grey[800] : Colors.white,
                      items: List.generate(
                        12,
                            (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              _getMonthName(index),
                              style: TextStyle(
                                color: dialogIsDarkMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedMonth = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: dialogIsDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onSelected(selectedYear, selectedMonth);
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: dialogIsDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}


Future<void> showYearMonthPickerIncome(
    BuildContext context,
    Function(int year, int month) onSelected,
    ) async {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

  bool isDarkMode = themeProvider.isDarkMode;

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      final dialogThemeProvider = Provider.of<ThemeProvider>(dialogContext);
      bool dialogIsDarkMode = dialogThemeProvider.isDarkMode;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: dialogIsDarkMode ? Colors.grey[900] : Colors.white,
            title: Text(
              'Select Year and Month',
              style: TextStyle(
                color: dialogIsDarkMode ? Colors.white : Colors.black,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Year:',
                      style: TextStyle(
                        color: dialogIsDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    DropdownButton<int>(
                      value: selectedYear,
                      dropdownColor:
                      dialogIsDarkMode ? Colors.grey[800] : Colors.white,
                      items: List.generate(
                        50,
                            (index) {
                          int year = DateTime.now().year - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: TextStyle(
                                color: dialogIsDarkMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedYear = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Month:',
                      style: TextStyle(
                        color: dialogIsDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    DropdownButton<int>(
                      value: selectedMonth,
                      dropdownColor:
                      dialogIsDarkMode ? Colors.grey[800] : Colors.white,
                      items: List.generate(
                        12,
                            (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              _getMonthName(index),
                              style: TextStyle(
                                color: dialogIsDarkMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedMonth = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: dialogIsDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onSelected(selectedYear, selectedMonth);
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: dialogIsDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}



class DayHeatmapPainter extends CustomPainter {
  final bool isDarkMode;
  final List<int> dailyCounts;

  DayHeatmapPainter({required this.isDarkMode, required this.dailyCounts});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1;

    final Paint boxPaint = Paint();
    final TextStyle labelStyle = TextStyle(
      color: isDarkMode ? Colors.white : Colors.black,
      fontSize: 12,
    );

    double columnWidth = size.width / 8;
    double maxHeight = size.height;
    double cornerRadius = 5;

    List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    double totalWidth = 7 * columnWidth;
    double startX = (size.width - totalWidth) / 2;

    for (int i = 0; i < 7; i++) {
      int dayIndex = i;

      double height = (dailyCounts[dayIndex] / 20) * maxHeight;
      height = (height * 0.7).clamp(0.0, maxHeight);

      double intensity = (height / maxHeight).clamp(1, 1.0);
      boxPaint.color = Colors.green.withOpacity(intensity);

      double scaledWidth = columnWidth * 0.4;

      RRect roundedRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX + i * columnWidth + (columnWidth - scaledWidth) / 4.8,
            maxHeight - height,
            scaledWidth,
            height),
        Radius.circular(cornerRadius),
      );

      canvas.drawRRect(roundedRect, boxPaint);

      final textPainter = TextPainter(
        text: TextSpan(text: dailyCounts[dayIndex].toString(), style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(startX + i * columnWidth + columnWidth / 4, maxHeight - height - 20));

      final dayLabel = TextPainter(
        text: TextSpan(text: daysOfWeek[dayIndex], style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      dayLabel.layout();
      dayLabel.paint(canvas, Offset(startX + i * columnWidth + columnWidth / 40, size.height + 1));
    }
  }

  @override
  bool shouldRepaint(covariant DayHeatmapPainter oldDelegate) {
    return oldDelegate.dailyCounts != dailyCounts ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}

Future<List<int>> getDailyCounts({DateTime? startDate, DateTime? endDate}) async {
  List<int> dailyCounts = List.filled(7, 0);
  Query query = FirebaseFirestore.instance.collection('loghistory');

  if (startDate != null && endDate != null) {
    query = query
        .where('scannedTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('scannedTime', isLessThan: Timestamp.fromDate(endDate.add(Duration(days: 1))));
  }

  print('Querying for date range: $startDate - $endDate');
  var querySnapshot = await query.get();

  if (querySnapshot.docs.isEmpty) {
    print('No documents found');
  } else {
    print('Found ${querySnapshot.docs.length} documents');
  }

  for (var doc in querySnapshot.docs) {
    var scannedTimeField = doc['scannedTime'];
    if (scannedTimeField is Timestamp) {
      DateTime scannedDate = scannedTimeField.toDate();
      print('Document ID: ${doc.id}, Scanned Time: $scannedDate');
    } else {
      print('Document ID: ${doc.id}, Scanned Time is not a Timestamp');
    }
  }

  Map<String, int> dayMap = {
    'monday': 0,
    'tuesday': 1,
    'wednesday': 2,
    'thursday': 3,
    'friday': 4,
    'saturday': 5,
    'sunday': 6,
  };

  for (var doc in querySnapshot.docs) {
    try {
      print('Processing document: ${doc.id}');

      if (doc['type'] == 'login') {
        var scannedTimeField = doc['scannedTime'];

        DateTime? parsedDate;
        if (scannedTimeField is Timestamp) {
          parsedDate = scannedTimeField.toDate();
        } else if (scannedTimeField is String) {
          try {
            parsedDate = DateTime.parse(scannedTimeField);
          } catch (e) {
            print('Error parsing scannedTime (String) for document ${doc.id}: $e');
          }
        }

        if (parsedDate != null) {
          int dayIndex = parsedDate.weekday - 1;

          dailyCounts[dayIndex]++;
          print('Incremented count for dayIndex: $dayIndex');
        } else {
          print('Skipping document ${doc.id} due to invalid scannedTime');
        }
      } else {
        print('Skipped document ${doc.id}, type: ${doc['type']}');
      }
    } catch (e) {
      print('Error processing document: ${doc.id}, error: $e');
    }
  }

  print('Final dailyCounts: $dailyCounts');
  return dailyCounts;
}



class IncomeBarPainter extends CustomPainter {
  final Map<int, int> monthlyIncome;
  final int totalIncome;
  final bool isDarkMode;

  IncomeBarPainter(this.totalIncome, this.monthlyIncome, {this.isDarkMode = false});

  @override
  void paint(Canvas canvas, Size size) {
    final Color barColor = isDarkMode ? Colors.green : Colors.green;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    final Paint barPaint = Paint()..color = barColor;
    final TextStyle labelStyle = TextStyle(color: textColor, fontSize: 12);

    double maxBarHeight = 20.0;
    double barWidth = size.width / 20;
    double gap = 10;

    final totalIncomeTextPainter = TextPainter(
      text: TextSpan(
        text: "Total Income: " '₱$totalIncome',
        style: labelStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    totalIncomeTextPainter.layout();
    totalIncomeTextPainter.paint(canvas, Offset((size.width - totalIncomeTextPainter.width) / 2, 10));

    double graphHeight = size.height - 30;

    int monthIndex = 0;
    monthlyIncome.forEach((month, income) {
      double barHeight = (income / 1000.0) * maxBarHeight;
      barHeight = barHeight.clamp(0.0, maxBarHeight);

      canvas.drawRect(
        Rect.fromLTWH(monthIndex * (barWidth + gap), graphHeight - barHeight, barWidth, barHeight),
        barPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: '₱$income', style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(monthIndex * (barWidth + gap) + (barWidth - textPainter.width) / 2, graphHeight - barHeight - 20));

      monthIndex++;
    });

    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    monthIndex = 0;
    monthlyIncome.forEach((month, _) {
      final monthLabel = monthNames[month - 1];
      final monthTextPainter = TextPainter(
        text: TextSpan(text: monthLabel, style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      monthTextPainter.layout();
      monthTextPainter.paint(canvas, Offset(monthIndex * (barWidth + gap) + (barWidth - monthTextPainter.width) / 2, size.height - 15));

      monthIndex++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class ActiveUsersPainter extends CustomPainter {
  final int activeUsersCount;
  final int bannedUsersCount;
  final int totalUsersCount;

  ActiveUsersPainter(this.activeUsersCount, this.bannedUsersCount, this.totalUsersCount);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint activeUsersPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final Paint bannedUsersPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final Paint inactiveUsersPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    double activeUsersAngle = 0.0;
    double bannedUsersAngle = 0.0;
    double inactiveUsersAngle = 0.0;

    if (totalUsersCount > 0) {
      double activePercentage = (activeUsersCount / totalUsersCount);
      double bannedPercentage = (bannedUsersCount / totalUsersCount);
      double inactivePercentage = 1.0 - activePercentage - bannedPercentage;

      if (inactivePercentage < 0) {
        inactivePercentage = 0;
      }

      activeUsersAngle = activePercentage * 2 * 3.14159;
      bannedUsersAngle = bannedPercentage * 2 * 3.14159;
      inactiveUsersAngle = inactivePercentage * 2 * 3.14159;
    }

    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 7;

    if (activeUsersAngle > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -3.14159 / 2, activeUsersAngle, true, activeUsersPaint);
    }

    if (bannedUsersAngle > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -3.14159 / 2 + activeUsersAngle, bannedUsersAngle, true, bannedUsersPaint);
    }

    if (inactiveUsersAngle > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -3.14159 / 2 + activeUsersAngle + bannedUsersAngle, inactiveUsersAngle, true, inactiveUsersPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ActiveUsersPainter) {
      return oldDelegate.activeUsersCount != activeUsersCount ||
          oldDelegate.bannedUsersCount != bannedUsersCount ||
          oldDelegate.totalUsersCount != totalUsersCount;
    }
    return true;
  }
}



