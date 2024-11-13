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

  @override
  void initState() {
    super.initState();
    fetchLoginCounts();
  }

  Future<void> fetchLoginCounts() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final startOfMonth = DateTime(now.year, now.month, 1);

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('logintime').get();
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
      appBar: AppBar(title: const Text('Graphs Admin')),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Customer Count Per Day
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 40),
                  painter: DayHeatmapPainter(dailyCounts),
                ),
              ],
            ),
          ),

          // Customer Count Per Month
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 200),
                  painter: MonthGraphPainter(monthlyCounts),
                ),
              ],
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
    final Paint gridPaint = Paint()..color = Colors.black..strokeWidth = 1;
    final Paint boxPaint = Paint();
    final TextStyle labelStyle = TextStyle(color: Colors.black, fontSize: 12);

    double columnWidth = size.width / 7;
    double maxHeight = size.height; // Set the maximum height for the rectangles
    double cornerRadius = 10; // Set the desired corner radius

    List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Get the current day of the week (1 = Monday, 7 = Sunday)
    DateTime now = DateTime.now();
    int currentDayIndex = now.weekday - 1; // Adjust to 0 = Monday, ..., 6 = Sunday

    // Draw the boxes and labels
    for (int i = 0; i < 7; i++) {
      int dayIndex = (currentDayIndex + i) % 7; // Wrap around for the days of the week

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
      dayLabel.paint(canvas, Offset(i * columnWidth + columnWidth / 40, size.height + 5));
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
    final Paint linePaint = Paint()..color = Colors.red..strokeWidth = 2; // Changed to red for distinction
    final TextStyle labelStyle = TextStyle(color: Colors.black, fontSize: 12);

    double columnWidth = size.width / 12;
    double rowHeight = size.height / 6;

    List<String> monthsOfYear = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (int i = 0; i < 6; i++) {
      // Draw horizontal grid lines
      canvas.drawLine(Offset(0, i * rowHeight), Offset(size.width, i * rowHeight), gridPaint);

      // Calculate the label value based on its position
      // Assuming 60 is at the top (i == 0) and 10 is at the bottom (i == 5)
      final labelValue = 60 - (i * 10);

      // Create the text painter for the label
      final textPainter = TextPainter(
        text: TextSpan(text: '$labelValue', style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      // Layout and paint the text
      textPainter.layout();
      textPainter.paint(canvas, Offset(-10, i * rowHeight - 6));
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
      final startPoint = Offset(
        month * columnWidth + columnWidth / 2,
        size.height - (monthlyCounts[month] * rowHeight / 10),
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
