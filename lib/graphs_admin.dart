import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'count_per_day.dart';
import 'count_per_month.dart';
import 'users_admin.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart'; // For permission handling
import 'income_admin.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

class GraphsAdminPage extends StatefulWidget {
  const GraphsAdminPage({Key? key}) : super(key: key);

  @override
  _GraphsAdminPageState createState() => _GraphsAdminPageState();
}

class _GraphsAdminPageState extends State<GraphsAdminPage> {
  List<int> dailyCounts = List.filled(7, 0); // Sun-Sat counts
  int totalIncome = 0;
  int activeUsersCount = 0;
  int totalUsersCount = 0;
  int bannedUsersCount = 0;
  Map<int, int> monthlyIncome = {};
  List<DocumentSnapshot> filteredDocs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    fetchLoginCounts();
    fetchTotalIncome();
    fetchMonthlyIncome();
    fetchBannedUsersCount();
    fetchActiveUsersCount();
    fetchUserCounts();
    getDailyCounts().then((counts) {
      setState(() {
        dailyCounts = counts; // Update the dailyCounts after fetching data
      });
    }).catchError((e) {
      print("Error fetching data: $e");
    });
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        fetchBannedUsersCount(),
        fetchActiveUsersCount(),
        fetchUserCounts(),
        getDailyCounts().then((counts) {
          dailyCounts = counts; // Update dailyCounts
        }),
      ]);
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _onRefresh() async {
    await _fetchAllData(); // Refresh all data
  }

  // Fetch active, banned users, total users, and income data before generating the report
  Future<void> fetchData() async {
    await fetchActiveUsersCount();
    await fetchBannedUsersCount();
    await fetchUserCounts();
    await fetchTotalIncome();
    await fetchMonthlyIncome();
    await fetchLoginCounts();

    // After fetching all necessary data, fetch filteredDocs based on the active users
    filteredDocs = await FirebaseFirestore.instance
        .collection('users')
        .where('userStatus', isEqualTo: 'Active') // Example filter (active users)
        .get()
        .then((snapshot) => snapshot.docs);

    // Generate the report with the fetched filteredDocs
    await generateReport(filteredDocs);
  }

  String formatDateTime(DateTime dateTime) {
    String year = dateTime.year.toString();
    String month = dateTime.month.toString().padLeft(2, '0'); // Ensure 2-digit month
    String day = dateTime.day.toString().padLeft(2, '0');     // Ensure 2-digit day
    String hour = dateTime.hour.toString().padLeft(2, '0');   // Ensure 2-digit hour
    String minute = dateTime.minute.toString().padLeft(2, '0'); // Ensure 2-digit minute
    String second = dateTime.second.toString().padLeft(2, '0'); // Ensure 2-digit second

    return '$year-$month-$day-$hour-$minute-$second';
  }

  Future<void> fetchActiveUsersCount() async {
    try {
      // Query to fetch documents where 'userStatus' is 'Active'
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userStatus', isEqualTo: 'Active') // Filter by 'Active' status
          .get();

      // Debugging: Print the number of documents fetched
      print("Fetched ${snapshot.docs.length} active users.");

      setState(() {
        activeUsersCount = snapshot.docs.length; // Count active users only
      });
    } catch (e) {
      // Handle errors (e.g., connection issues)
      print("Error fetching active users count: $e");
    }
  }

  Future<void> fetchUserCounts() async {
    try {
      // Fetch all users from the 'users' collection
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      // Debugging: Print the total number of users fetched
      print("Fetched ${usersSnapshot.docs.length} total users.");

      setState(() {
        totalUsersCount = usersSnapshot.docs
            .length; // Total number of users in the collection
      });
    } catch (e) {
      // Handle any errors that occur during the fetch
      print("Error fetching total users count: $e");
    }
  }

  Future<void> fetchBannedUsersCount() async {
    try {
      // Query to fetch documents where 'userStatus' is 'Active'
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userStatus', isEqualTo: 'Banned') // Filter by 'Banned' status
          .get();

      // Debugging: Print the number of documents fetched
      print("Fetched ${snapshot.docs.length} banned users.");

      setState(() {
        bannedUsersCount = snapshot.docs.length; // Count active users only
      });
    } catch (e) {
      // Handle errors (e.g., connection issues)
      print("Error fetching banned users count: $e");
    }
  }

  Future<void> fetchTotalIncome() async {
    // Clear the previous total income before fetching new data
    totalIncome = 0;

    // Fetch all documents from the 'cashinlogs' collection
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(
        'cashinlogs').get();

    // Debugging: Print the document IDs and the amount field to check if it's correctly accessed
    for (var doc in snapshot.docs) {
      print('Document ID: ${doc.id}');
      print('Amount Field: ${doc['amount']}'); // Log the 'amount' field

      // If 'amount' exists and is of type int, add to totalIncome
      var amount = doc['amount'];
      if (amount is int) {
        totalIncome += amount;
      } else if (amount is double) {
        totalIncome += amount.toInt(); // Convert double to int if necessary
      } else {
        print("No valid amount field or wrong type in document ${doc.id}");
      }
    }

    // Trigger UI update
    setState(() {});
  }

  // Fetch data from Firestore and calculate total and monthly income
  Future<void> fetchMonthlyIncome() async {
    Map<int, int> incomeByMonth = {}; // Local map to store income by month

    // Fetch all documents from the 'cashinlogs' collection
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(
        'cashinlogs').get();

    for (var doc in snapshot.docs) {
      DateTime scannedDate = (doc['scannedTime'] as Timestamp).toDate();
      int month = scannedDate.month; // Get the month from the scannedTime
      int amount = doc['amount'] ??
          0; // Get the amount field, default to 0 if null

      // Sum income for each month
      if (incomeByMonth.containsKey(month)) {
        incomeByMonth[month] = incomeByMonth[month]! + amount;
      } else {
        incomeByMonth[month] = amount;
      }
    }

    // Calculate total income (sum of all monthly income)
    totalIncome = incomeByMonth.values.reduce((a, b) => a + b);

    // Update the state with monthly income data
    setState(() {
      monthlyIncome = incomeByMonth;
    });
  }

  List<int> monthlyCounts = List.filled(12, 0); // Jan-Dec counts

  Future<void> fetchLoginCounts() async {

    final now = DateTime.now().toUtc(); // Get the current UTC time
    final startOfMonth = DateTime.utc(now.year, now.month, 1); // Start of this month
    final endOfMonth = DateTime.utc(now.year, now.month + 1, 1).subtract(Duration(seconds: 1)); // End of this month

    // Debug: Print the range you're querying
    print("Start of month: $startOfMonth");
    print("End of month: $endOfMonth");

    // Fetch documents from the loghistory collection
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('loghistory').get();

    // Check if there are any documents in the snapshot
    print("Number of documents fetched: ${snapshot.docs.length}");

    // Iterate over the documents
    for (var doc in snapshot.docs) {
      // Check if the 'type' field is 'login'
      if (doc['type'] == 'login') {
        // Extract the timestamp and convert to DateTime
        if (doc['scannedTime'] is Timestamp) {
          DateTime loginTime = (doc['scannedTime'] as Timestamp).toDate();  // Convert Timestamp to DateTime

          // Debug: Print the login time for each document
          print("Login Time: $loginTime");

          // Extract the month component of the login time
          int loginMonth = loginTime.month;

          // Debug: Print the login month
          print("Login Month: $loginMonth");

          // Use a switch statement to update the monthlyCounts based on loginMonth
          switch (loginMonth) {
            case 1:
              monthlyCounts[0]++; // January
              break;
            case 2:
              monthlyCounts[1]++; // February
              break;
            case 3:
              monthlyCounts[2]++; // March
              break;
            case 4:
              monthlyCounts[3]++; // April
              break;
            case 5:
              monthlyCounts[4]++; // May
              break;
            case 6:
              monthlyCounts[5]++; // June
              break;
            case 7:
              monthlyCounts[6]++; // July
              break;
            case 8:
              monthlyCounts[7]++; // August
              break;
            case 9:
              monthlyCounts[8]++; // September
              break;
            case 10:
              monthlyCounts[9]++; // October
              break;
            case 11:
              monthlyCounts[10]++; // November
              break;
            case 12:
              monthlyCounts[11]++; // December
              break;
            default:
              print("Invalid month: $loginMonth");
              break;
          }

          // Debug: Print the updated monthlyCounts after each login
          print("Updated monthlyCounts: $monthlyCounts");
        } else {
          print("Invalid 'scannedTime' field: ${doc['scannedTime']}");
        }
      } else {
        // If it's not a login, don't count it
        print("Skipping document with type: ${doc['type']}");
      }
    }

    // Debug: Print the final monthly counts
    print("Final Monthly login counts: $monthlyCounts");
  }

  Future<void> generateReport(List<DocumentSnapshot> filteredDocs) async {
    try {
      // 1. Gather all the data into a formatted string
      String report = 'User Report\n';
      report += '==========================\n';

      // Initialize counters
      int totalUsersCount = 0;
      int activeUsersCount = 0;
      int bannedUsersCount = 0;
      double totalIncome = 0;
      List<int> dailyCounts = List.filled(7, 0); // Daily logins count (Sun-Sat)
      List<double?> monthlyIncome = List.filled(12, 0); // Monthly income

      // Process filteredDocs for the report generation
      for (var doc in filteredDocs) {
        totalUsersCount++;
        if (doc['userStatus'] == 'Active') {
          activeUsersCount++;
        } else if (doc['userStatus'] == 'Banned') {
          bannedUsersCount++;
        }
        totalIncome += doc['wallet'] ?? 0;

        // Assume document contains 'lastLogin' field for login date
        var lastLogin = doc['lastLogin']; // Fetch lastLogin field
        String loginDateString = lastLogin is String ? lastLogin : '';

        DateTime? loginDate; // Nullable DateTime to handle null values
        if (loginDateString == "N/A") {
          loginDate = null; // Treat "N/A" as no valid date, set to null
        } else if (lastLogin is Timestamp) {
          loginDate = lastLogin.toDate(); // Convert Timestamp to DateTime
        } else if (loginDateString.isNotEmpty) {
          try {
            // Attempt to parse the string to a DateTime
            loginDate = DateTime.parse(loginDateString); // Convert string to DateTime
          } catch (e) {
            // Handle invalid date format (log the error and set a default date)
            print('Invalid date format for lastLogin: $lastLogin');
            loginDate = DateTime.now(); // Set a default date
          }
        } else {
          // Handle missing or invalid data (log the error and set a default date)
          print('Invalid lastLogin data: $lastLogin');
          loginDate = DateTime.now(); // Or any default date you'd like to set
        }

        // Now you can check if the loginDate is null and use "N/A" in the report
        String loginDateDisplay = loginDate == null ? "N/A" : loginDate.toString();

        int dayOfWeek = loginDate?.weekday ?? 0; // Get the weekday (1=Monday, ..., 7=Sunday)
        if (dayOfWeek > 0) {
          // Adjust indexing if necessary. Map to 0-based index.
          dailyCounts[dayOfWeek % 7]++;  // Correct day index mapping
        }

        int month = loginDate?.month ?? 0; // Adjust for 0-based index
        if (month > 0) {
          monthlyIncome[month - 1] = (monthlyIncome[month - 1] ?? 0) + (doc['wallet'] ?? 0);
        }

        String userId = doc['userID'] ?? 'Unknown';

        // Append the login date and user ID to the report (use "N/A" if the date is invalid)
        report += "User: $userId 's Last Login: $loginDateDisplay\n";
      }

      // Append data to the report string
      report += 'Total Users: $totalUsersCount\n';
      report += 'Active Users: $activeUsersCount\n';
      report += 'Banned Users: $bannedUsersCount\n';
      report += 'Total Income: \$${totalIncome.toString()}\n';

      // Append daily login counts to the report string
      report += '\nDaily Login Counts (Sun-Sat):\n';
      report += '----------------------------\n';
      List<String> daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      for (int i = 0; i < 7; i++) {
        report += '${daysOfWeek[i]}: ${dailyCounts[i]} logins\n';
      }

      report += '\nMonthly Income:\n';
      report += '----------------\n';
      for (int i = 0; i < 12; i++) {
        String monthName = DateTime(2024, i + 1).toString().substring(5, 7); // Get the month name
        report += '$monthName: \$${monthlyIncome[i] ?? 0}\n';
      }

      // Get the current date and time for the file name
      String currentDateTime = formatDateTime(DateTime.now());

      // Define the path to external storage (e.g., "/storage/emulated/0/FitTrack")
      String fitTrackPath = '/storage/emulated/0/FitTrack';

      // Create the FitTrack directory if it doesn't exist
      final fitTrackFolder = Directory(fitTrackPath);
      if (!await fitTrackFolder.exists()) {
        await fitTrackFolder.create(recursive: true);
      }

      // Create the "General Reports" subdirectory inside FitTrack
      final generalReportsFolder = Directory('$fitTrackPath/General Reports');
      if (!await generalReportsFolder.exists()) {
        await generalReportsFolder.create(recursive: true);
      }

      // Define the file path inside the "General Reports" folder with the current date and time
      String filePath = '$fitTrackPath/General Reports/GeneralReport_$currentDateTime.txt';

      // Write the report to the file
      final file = File(filePath);
      await file.writeAsString(report);

      // Optionally, show a success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report generated at $filePath')));
    } catch (e) {
      print('Error generating report: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating report')));
    }
    await _requestPermissions();
  }

// Example method to trigger data fetching and report generation
  void triggerReportGeneration() async {
    await fetchData();
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
                      ? 'assets/images/dark_bg.png'  // Dark mode background
                      : 'assets/images/bg.png',      // Light mode background
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        // Title at the top
        Positioned(
        top: 40, // Adjust the top position as needed
        left: MediaQuery.of(context).size.width / 2 - 50, // Center the title horizontally
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the content within the Row
          children: [
            Icon(
              Icons.edit_note_outlined,
              size: 24, // Adjust the icon size as needed
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white // Black in dark mode
                  : Colors.green, // Green in light mode
            ),
            Text(
              'Reports',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(width: 8), // Adds space between the title and the icon
          ],
        ),
      ),
      // Positioned FloatingActionButton for navigation
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

          // Refreshable scrollable content
      Padding(
        padding: const EdgeInsets.only(top: 100.0), // Space below the title
        child: RefreshIndicator(
          onRefresh: _onRefresh, // Trigger refresh
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Always allow scrolling
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Customer Count Per Day
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
                    child: Column(
                      children: [
                        Text(
                          'CUSTOMER COUNT PER DAY',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CustomPaint(
                          size: Size(MediaQuery.of(context).size.width, 40),
                          painter: DayHeatmapPainter(isDarkMode: isDarkMode, dailyCounts: dailyCounts),
                        ),
                      ],
                    ),
                  ),
                ),

                  // Customer Count Per Month
                  GestureDetector(
                    onTap: () {
                      // Navigate to the CustomerInfoPage
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
                          Text(
                            'CUSTOMER COUNT PER MONTH',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          CustomPaint(
                            size: Size(MediaQuery.of(context).size.width, 80),
                            painter: MonthGraphPainter(isDarkMode: isDarkMode, monthlyCounts: monthlyCounts),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Monthly Income
                GestureDetector(
                  onTap: () {
                    // Navigate to the IncomeAdminPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IncomeAdminPage(), // Change to IncomeAdminPage
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
                        Text(
                          'Monthly Income',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CustomPaint(
                          size: Size(MediaQuery.of(context).size.width, 80),
                          painter: IncomeBarPainter(isDarkMode: isDarkMode, totalIncome, monthlyIncome),
                        ),
                      ],
                    ),
                  ),
                ),

                // Active Users Count Graph
                  GestureDetector(
                    onTap: () {
                      // Navigate to the ActiveUsersPage
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Box for "On Approval Users"
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'On Approval Users',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              // Box for "Banned Users"
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Banned Users',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              // Box for "Active Users"
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Active Users',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Padding for the "Generate Report" button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        // First, ensure that filteredDocs is populated by calling fetchData()
                        await fetchData();

                        // Check if filteredDocs has data
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
                          await generateReport(filteredDocs); // Pass filteredDocs

                          // Close the loading dialog
                          Navigator.of(context).pop();

                          // Show a success dialog with a success message
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
                          // Show an error dialog if filteredDocs is empty (no data available)
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

  // Constructor accepting both isDarkMode and monthlyCounts
  MonthGraphPainter({required this.isDarkMode, required this.monthlyCounts});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()..color = isDarkMode ? Colors.white : Colors.black..strokeWidth = 1;
    final Paint linePaint = Paint()..color = Colors.green..strokeWidth = 2;
    final TextStyle labelStyle = TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 12);

    double columnWidth = size.width / 12; // 12 columns for each month
    double rowHeight = size.height / 3;   // Adjusted height for better visibility

    // Define month labels
    List<String> monthsOfYear = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    // Draw the 3 horizontal grid lines with values for scale
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(Offset(15, i * rowHeight), Offset(size.width, i * rowHeight), gridPaint);
      final labelValue = (30 - (i * 10));  // Adjusting the grid labels based on counts
      final textPainter = TextPainter(
        text: TextSpan(text: '$labelValue', style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-5, i * rowHeight - 6));
    }

    // Draw the month labels
    for (int i = 0; i < 12; i++) {
      final monthLabel = TextPainter(
        text: TextSpan(text: monthsOfYear[i], style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      monthLabel.layout();
      monthLabel.paint(canvas, Offset(i * columnWidth + columnWidth / 4, size.height + 5));
    }

    // Draw the line graph connecting the points (monthly counts)
    for (int month = 0; month < monthlyCounts.length - 1; month++) {
      // Adjust normalization factor for better scaling of values
      final normalizedValueStart = (monthlyCounts[month] / 10).clamp(0, 30);  // Adjust divisor for better scaling
      final normalizedValueEnd = (monthlyCounts[month + 1] / 10).clamp(0, 30);

      final startPoint = Offset(
        month * columnWidth + columnWidth / 2,  // Start of the month
        size.height - normalizedValueStart * rowHeight / 5,  // Y-position based on count
      );
      final endPoint = Offset(
        (month + 1) * columnWidth + columnWidth / 2,  // End of the month
        size.height - normalizedValueEnd * rowHeight / 5,  // Y-position for the next month
      );

      canvas.drawLine(startPoint, endPoint, linePaint);  // Draw the line between points
    }

    // Print monthly counts on the graph for debugging
    for (int month = 0; month < monthlyCounts.length; month++) {
      final countText = '${monthlyCounts[month]}';
      final countPainter = TextPainter(
        text: TextSpan(text: countText, style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      countPainter.layout();

      // Print count in the middle of each month's column
      countPainter.paint(
        canvas,
        Offset(month * columnWidth + columnWidth / 2 - countPainter.width / 2,
            size.height - (monthlyCounts[month] / 10).clamp(0, 30) * rowHeight / 5 - 15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Repaint only if the data has changed
    return oldDelegate is MonthGraphPainter && oldDelegate.monthlyCounts != monthlyCounts;
  }
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
      color: isDarkMode ? Colors.white : Colors.black, // Fix for label color
      fontSize: 12,
    );


    double columnWidth = size.width / 8; // Reduce the divisor to make bars smaller
    double maxHeight = size.height; // Set the maximum height for the rectangles
    double cornerRadius = 5; // Smaller corner radius to make it less rounded

// Fixed days of the week starting from Sunday
    List<String> daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// Calculate the starting position to center the bars
    double totalWidth = 7 * columnWidth; // Total width of all bars
    double startX = (size.width - totalWidth) / 2; // Calculate the starting X position to center the bars

// Draw the boxes and labels in fixed order
    for (int i = 0; i < 7; i++) {
      int dayIndex = i;

      // Calculate the height of the rectangle based on daily counts
      double height = (dailyCounts[dayIndex] / 20) * maxHeight; // Scale according to your needs
      height = (height * 0.7).clamp(0.0, maxHeight); // Reduce the height by scaling it down to 70%

      // Calculate intensity based on height (i.e., vertical growth)
      double intensity = (height / maxHeight).clamp(1, 1.0); // Adjust color intensity based on height
      boxPaint.color = Colors.green.withOpacity(intensity); // Use intensity to adjust color

      // **Scale the width** of the bars by a factor (optional)
      double scaledWidth = columnWidth * 0.4; // Make the width of the bars 80% of the column width

      // Create a smaller rounded rectangle for the day's count with a smaller corner radius
      RRect roundedRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX + i * columnWidth + (columnWidth - scaledWidth) / 4.8, // Center the smaller width within the column
            maxHeight - height,
            scaledWidth, // Scaled width
            height), // Height remains the same as before
        Radius.circular(cornerRadius), // Smaller corner radius
      );

      // Draw the rounded rectangle
      canvas.drawRRect(roundedRect, boxPaint);

      // Draw the customer count
      final textPainter = TextPainter(
        text: TextSpan(text: dailyCounts[dayIndex].toString(), style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(startX + i * columnWidth + columnWidth / 4, maxHeight - height - 20)); // Adjust X position with startX

      // Draw the day label
      final dayLabel = TextPainter(
        text: TextSpan(text: daysOfWeek[dayIndex], style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      dayLabel.layout();
      dayLabel.paint(canvas, Offset(startX + i * columnWidth + columnWidth / 40, size.height + 1)); // Adjust X position with startX
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


// Fetch data from your loghistory collection
Future<List<int>> getDailyCounts() async {
  List<int> dailyCounts = List.filled(7, 0); // Initialize the list to store counts for each day (Sunday to Saturday)

  // Fetch the logs from the `loghistory` collection
  var querySnapshot = await FirebaseFirestore.instance.collection('loghistory').get();

  // Iterate over the logs and count occurrences based on the `day` field and filter by event type
  querySnapshot.docs.forEach((doc) {
    String day = doc['day'].toString().toLowerCase(); // Get the 'day' field (e.g., "monday")
    String eventType = doc['type']; // Assuming eventType is a field in your document

    // Proceed only if the event type is "login"
    if (eventType == "login") {
      // Map the day string to the correct index
      int dayIndex;
      switch (day) {
        case 'monday':
          dayIndex = 1;
          break;
        case 'tuesday':
          dayIndex = 2;
          break;
        case 'wednesday':
          dayIndex = 3;
          break;
        case 'thursday':
          dayIndex = 4;
          break;
        case 'friday':
          dayIndex = 5;
          break;
        case 'saturday':
          dayIndex = 6;
          break;
        case 'sunday':
          dayIndex = 0;
          break;
        default:
          dayIndex = -1; // Handle case where 'day' is not recognized
          break;
      }

      if (dayIndex != -1) {
        dailyCounts[dayIndex]++; // Increment the count for the corresponding day of the week
      }
    }
  });

  return dailyCounts;
}


class IncomeBarPainter extends CustomPainter {
  final Map<int, int> monthlyIncome; // Map to store income per month
  final int totalIncome;
  final bool isDarkMode; // New parameter for dark mode

  IncomeBarPainter(this.totalIncome, this.monthlyIncome, {this.isDarkMode = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Colors for light and dark mode
    final Color barColor = isDarkMode ? Colors.green : Colors.green; // Bar color
    final Color textColor = isDarkMode ? Colors.white : Colors.black; // Text color

    final Paint barPaint = Paint()..color = barColor;
    final TextStyle labelStyle = TextStyle(color: textColor, fontSize: 12);

    // Set a fixed max bar height
    double maxBarHeight = 200.0; // Adjust this value for the max height of the highest bar
    double barWidth = size.width / 20; // 12 months
    double gap = 10; // Space between the bars

    // Draw the "Total Income" label at the top center of the graph
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

    // Adjust the space for bars so that month labels don't overlap
    double graphHeight = size.height - 30; // Deduct space for the total income label and month labels

    // Draw the bars for each month
    int monthIndex = 0;
    monthlyIncome.forEach((month, income) {
      // Scale income based on max income value of 1000
      double barHeight = (income / 1000.0) * maxBarHeight; // Scale income for each month
      barHeight = barHeight.clamp(0.0, maxBarHeight); // Clamp to prevent overflow

      // Draw the income bar for each month (starting from the bottom)
      canvas.drawRect(
        Rect.fromLTWH(monthIndex * (barWidth + gap), graphHeight - barHeight, barWidth, barHeight),
        barPaint,
      );

      // Draw the income value on top of the bar
      final textPainter = TextPainter(
        text: TextSpan(text: '₱$income', style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(monthIndex * (barWidth + gap) + (barWidth - textPainter.width) / 2, graphHeight - barHeight - 20));

      monthIndex++;
    });

    // Draw month labels at the bottom of the graph
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    monthIndex = 0;
    monthlyIncome.forEach((month, _) {
      final monthLabel = monthNames[month - 1]; // Month labels are 1-based
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
      ..color = Colors.green // Color for the active users segment
      ..style = PaintingStyle.fill;

    final Paint bannedUsersPaint = Paint()
      ..color = Colors.red // Color for the banned users segment
      ..style = PaintingStyle.fill;

    final Paint inactiveUsersPaint = Paint()
      ..color = Colors.yellow // Color for inactive users segment
      ..style = PaintingStyle.fill;

    double activeUsersAngle = 0.0;
    double bannedUsersAngle = 0.0;
    double inactiveUsersAngle = 0.0;

    // Ensure the total users count is greater than zero to avoid division by zero
    if (totalUsersCount > 0) {
      // Calculate the percentages based on user counts
      double activePercentage = (activeUsersCount / totalUsersCount);
      double bannedPercentage = (bannedUsersCount / totalUsersCount);
      double inactivePercentage = 1.0 - activePercentage - bannedPercentage;

      // Ensure inactive percentage isn't negative
      if (inactivePercentage < 0) {
        inactivePercentage = 0;
      }

      // Calculate the angles for each segment (in radians)
      activeUsersAngle = activePercentage * 2 * 3.14159;
      bannedUsersAngle = bannedPercentage * 2 * 3.14159;
      inactiveUsersAngle = inactivePercentage * 2 * 3.14159;
    }

    // Center of the pie chart
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 7; // Adjusted for a smaller pie chart

    // Draw the active users segment
    if (activeUsersAngle > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -3.14159 / 2, activeUsersAngle, true, activeUsersPaint);
    }

    // Draw the banned users segment
    if (bannedUsersAngle > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -3.14159 / 2 + activeUsersAngle, bannedUsersAngle, true, bannedUsersPaint);
    }

    // Draw the inactive users segment
    if (inactiveUsersAngle > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -3.14159 / 2 + activeUsersAngle + bannedUsersAngle, inactiveUsersAngle, true, inactiveUsersPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Only repaint if the active, banned, or total users count has changed
    if (oldDelegate is ActiveUsersPainter) {
      return oldDelegate.activeUsersCount != activeUsersCount ||
          oldDelegate.bannedUsersCount != bannedUsersCount ||
          oldDelegate.totalUsersCount != totalUsersCount;
    }
    return true;
  }
}


