import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GraphsAdminPage extends StatefulWidget {
  const GraphsAdminPage({Key? key}) : super(key: key);

  @override
  _GraphsAdminPageState createState() => _GraphsAdminPageState();
}

class _GraphsAdminPageState extends State<GraphsAdminPage> {
  List<int> dailyCounts = List.filled(7, 0); // Sun-Sat counts
  List<int> monthlyCounts = List.filled(12, 0); // Jan-Dec counts
  int totalIncome = 0;
  int activeUsersCount = 0;
  int totalUsersCount = 0;
  int bannedUsersCount = 0;
  Map<int, int> monthlyIncome = {};

  @override
  void initState() {
    super.initState();
    fetchLoginCounts();
    fetchTotalIncome();
    fetchMonthlyIncome();
    fetchBannedUsersCount();
    fetchActiveUsersCount();
    fetchUserCounts();
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


  Future<void> fetchLoginCounts() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final startOfMonth = DateTime(now.year, now.month, 1);

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(
        'logintime').get();
    for (var doc in snapshot.docs) {
      DateTime loginTime = (doc['scannedTime'] as Timestamp).toDate();
      if (loginTime.isAfter(startOfWeek)) {
        int dayIndex = loginTime.weekday % 7;
        dailyCounts[dayIndex]++;
      }
      if (loginTime.isAfter(startOfMonth)) {
        int monthIndex = loginTime.month - 1;
        monthlyCounts[monthIndex]++;
      }
    }
    setState(() {}); // Refresh the UI with new data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100], // Light green background
      body: Stack(
        children: [
          // Title at the top
          Positioned(
            top: 40, // Adjust the top position as needed
            left: MediaQuery.of(context).size.width / 2 - 50, // Center the title horizontally
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the content within the Row
              children: [
                Icon(
                  Icons.table_view,
                  size: 24, // Adjust the icon size as needed
                  color: Colors.green, // Set the icon color
                ),
                Text(
                  'Graphs',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24, // Adjust the font size as needed
                  ),
                ),
                const SizedBox(width: 8), // Adds space between the title and the icon
              ],
            ),
          ),

          Center( // Centers the entire content within the page
            child: SingleChildScrollView( // Ensure everything is scrollable
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // Center the content vertically
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Customer Count Per Day
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CUSTOMER COUNT PER DAY',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        CustomPaint(
                          size: Size(MediaQuery
                              .of(context)
                              .size
                              .width, 40),
                          painter: DayHeatmapPainter(dailyCounts),
                        ),
                      ],
                    ),
                  ),

                  // Customer Count Per Month
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CUSTOMER COUNT PER MONTH',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        CustomPaint(
                          size: Size(MediaQuery
                              .of(context)
                              .size
                              .width, 80),
                          painter: MonthGraphPainter(monthlyCounts),
                        ),
                      ],
                    ),
                  ),

                  // Monthly Income
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Monthly Income',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        CustomPaint(
                          size: Size(MediaQuery
                              .of(context)
                              .size
                              .width, 80),
                          painter: IncomeBarPainter(totalIncome, monthlyIncome),
                        ),
                      ],
                    ),
                  ),

                  // Active Users Count Graph
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Users Chart',
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        CustomPaint(
                          size: Size(MediaQuery
                              .of(context)
                              .size
                              .width, 80),
                          painter: ActiveUsersPainter(
                              activeUsersCount, bannedUsersCount,
                              totalUsersCount),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Box for "On Approval Users"
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
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

                  // Padding for the "Generate Report" button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Add your report generation logic here
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(MediaQuery
                            .of(context)
                            .size
                            .width - 32, 50),
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        'Generate Report',
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

          // Positioned button at the top left
          Positioned(
            top: 20,
            left: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.green,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Daily Heatmap Painter
class DayHeatmapPainter extends CustomPainter {
  final List<int> dailyCounts;

  DayHeatmapPainter(this.dailyCounts);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()..color = Colors.green..strokeWidth = 1;
    final Paint boxPaint = Paint();
    final TextStyle labelStyle = TextStyle(color: Colors.black, fontSize: 12);

    double columnWidth = size.width / 7;
    double maxHeight = size.height; // Set the maximum height for the rectangles
    double cornerRadius = 10; // Set the desired corner radius

    // Fixed days of the week starting from Sunday
    List<String> daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    // Draw the boxes and labels in fixed order
    for (int i = 0; i < 7; i++) {
      // Use i as the index directly to follow the fixed day order
      int dayIndex = i;

      // Calculate the height of the rectangle based on daily counts
      double height = (dailyCounts[dayIndex] / 50) * maxHeight; // Scale according to your needs
      height = height.clamp(0.0, maxHeight); // Ensure height doesn't exceed maxHeight

      double intensity = (dailyCounts[dayIndex] / 50).clamp(0.2, 1.0); // Adjust color intensity
      boxPaint.color = Colors.blue.withOpacity(intensity); // Changed to blue for distinction

      // Create a rounded rectangle for the day's count
      RRect roundedRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * columnWidth, maxHeight - height, columnWidth, height), // Rectangle position and size
        Radius.circular(cornerRadius), // Corner radius
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
      textPainter.paint(canvas, Offset(i * columnWidth + columnWidth / 4, maxHeight - height - 20)); // Adjust Y position for count

      // Draw the day label
      final dayLabel = TextPainter(
        text: TextSpan(text: daysOfWeek[dayIndex], style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      dayLabel.layout();
      dayLabel.paint(canvas, Offset(i * columnWidth + columnWidth / 40, size.height + 1));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}



// Monthly Line Graph Painter
class MonthGraphPainter extends CustomPainter {
  final List<int> monthlyCounts;

  MonthGraphPainter(this.monthlyCounts);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()..color = Colors.black..strokeWidth = 1;
    final Paint linePaint = Paint()..color = Colors.green..strokeWidth = 2; // Red for distinction
    final TextStyle labelStyle = TextStyle(color: Colors.black, fontSize: 12);

    double columnWidth = size.width / 12;
    double rowHeight = size.height / 4; // Divide the height into 3 rows

    // Define month labels
    List<String> monthsOfYear = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    // Draw the 3 main horizontal grid lines
    for (int i = 0; i < 4; i++) {
      // Draw the grid line
      canvas.drawLine(Offset(15, i * rowHeight), Offset(size.width, i * rowHeight), gridPaint);

      // Label each line (30 at top, 20 in middle, 10 at bottom)
      final labelValue = 30 - (i * 10);
      final textPainter = TextPainter(
        text: TextSpan(text: '$labelValue', style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-5, i * rowHeight - 6)); // Adjusted for label positioning
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

    // Draw the line graph connecting the points
    for (int month = 0; month < monthlyCounts.length - 1; month++) {
      final startPoint = Offset(
        month * columnWidth + columnWidth / 2,
        size.height - (monthlyCounts[month] * rowHeight / 10), // Scale based on max of 30
      );
      final endPoint = Offset(
        (month + 1) * columnWidth + columnWidth / 2,
        size.height - (monthlyCounts[month + 1] * rowHeight / 10),
      );
      canvas.drawLine(startPoint, endPoint, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class IncomeBarPainter extends CustomPainter {
  final Map<int, int> monthlyIncome; // Map to store income per month
  final int totalIncome;

  IncomeBarPainter(this.totalIncome, this.monthlyIncome);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint barPaint = Paint()..color = Colors.green; // Use purple for income
    final TextStyle labelStyle = TextStyle(color: Colors.black, fontSize: 12);

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


