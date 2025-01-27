import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

class PreferencesPage extends StatefulWidget {
  @override
  _PreferencesPageState createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _items = [
    'Home',
    'Alerts',
    'History',
    'Profile',
    'Cash-in'
  ];
  final Map<String, bool> _selectedItems = {
    'Home': false,
    'Alerts': false,
    'History': false,
    'Profile': false,
    'Cash-in': false,
  };

  final Map<String, String> _selectedIntervals = {
    "Stay Hydrated": "1 minute",
    "Proper Form": "2 minutes",
    "Windows": "3 minutes",
    "CAYGO": "4 minutes",
  };


  final List<String> _intervalOptions = [
    "Never",
    "1 minute",
    "10 minutes",
    "30 minutes",
    "1 hour",
    "2 hours",
    "2 minutes",
    "3 minutes",
    "4 minutes",
  ];

  final Map<String, int> intervalToMinutes = {
    '1 minute': 1,
    '2 minutes': 2,
    '3 minutes': 3,
    '4 minutes': 4,
    '10 minutes': 10,
    '30 minutes': 30,
    '1 hour': 60,
    '2 hours': 120,
    'Never': 99999,
  };


  void _showAlertsDialog(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isDarkMode = themeProvider.isDarkMode;

    final currentUserID = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserID == null) {
      print("No user is logged in");
      return;
    }

    final userDocSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserID)
        .get();

    if (!userDocSnapshot.exists) {
      print("User document not found");
      return;
    }

    final userDoc = userDocSnapshot.data();
    final actualUserID = userDoc?['userID'] ?? 'defaultUserID';

    if (actualUserID == null) {
      print("UserID not found in user document");
      return;
    }

    for (String alertType in _selectedIntervals.keys) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('alerts')
          .where('title', isEqualTo: alertType)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final alertData = querySnapshot.docs.first.data();
        final durationField = 'duration$actualUserID';
        final duration = alertData[durationField];

        if (duration != null) {
          String intervalString = '';
          switch (duration) {
            case 1:
              intervalString = '1 minute';
              break;
            case 2:
              intervalString = '2 minutes';
              break;
            case 3:
              intervalString = '3 minutes';
              break;
            case 4:
              intervalString = '4 minutes';
              break;
            case 10:
              intervalString = '10 minutes';
              break;
            case 30:
              intervalString = '30 minutes';
              break;
            case 60:
              intervalString = '1 hour';
              break;
            case 120:
              intervalString = '2 hours';
              break;
            default:
              intervalString = 'Never';
          }

          _selectedIntervals[alertType] = intervalString;
        }
      } else {
        print("No alert found for title $alertType");
      }
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text("Change Alerts Interval"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (String alertType in _selectedIntervals.keys)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alertType,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            DropdownButton<String>(
                              value: _selectedIntervals[alertType],
                              isExpanded: true,
                              items: _intervalOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors
                                          .black,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) async {
                                if (newValue != null) {
                                  setDialogState(() {
                                    _selectedIntervals[alertType] = newValue;
                                  });

                                  print(
                                      "Selected interval for $alertType: $newValue");

                                  final int durationInMinutes = intervalToMinutes[newValue] ??
                                      0;

                                  final querySnapshot = await FirebaseFirestore
                                      .instance
                                      .collection('alerts')
                                      .where('title', isEqualTo: alertType)
                                      .get();

                                  if (querySnapshot.docs.isNotEmpty) {
                                    final alertDocRef = querySnapshot.docs.first
                                        .reference;
                                    final durationField = 'duration$actualUserID';

                                    try {
                                      await alertDocRef.update({
                                        durationField: durationInMinutes,
                                      });
                                      print(
                                          'Updated $alertType to $newValue ($durationInMinutes minutes) in Firestore');
                                    } catch (e) {
                                      print(
                                          'Error updating Firestore for $alertType: $e');
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveIntervals() async {
    final currentUserID = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserID == null) {
      print("No user is logged in");
      return;
    }

    final userDocSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserID)
        .get();

    if (!userDocSnapshot.exists) {
      print("User document not found");
      return;
    }

    final userDoc = userDocSnapshot.data();
    final actualUserID = userDoc?['userID'];

    if (actualUserID == null) {
      print("UserID not found in user document");
      return;
    }

    Map<String, int> intervalToMinutes = {
      "Never": 999999,
      "1 minute": 1,
      "2 minutes": 2,
      "3 minutes": 3,
      "4 minutes": 4,
      "10 minutes": 10,
      "30 minutes": 30,
      "1 hour": 60,
      "2 hours": 120,
    };

    for (var alertType in _selectedIntervals.keys) {
      final String? interval = _selectedIntervals[alertType];
      if (interval == null) {
        print("Interval not found for alert type: $alertType");
        continue;
      }

      int durationInMinutes = intervalToMinutes[interval] ?? 0;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('alerts')
          .where('title', isEqualTo: alertType)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No alert found for title $alertType");
        continue;
      }

      final alertDocRef = querySnapshot.docs.first.reference;

      final dynamicFieldName = 'duration$actualUserID';

      try {
        await alertDocRef.update({
          dynamicFieldName: durationInMinutes,
        });

        print(
            'Updated $alertType with interval $interval ($durationInMinutes minutes) for user $actualUserID');
      } catch (e) {
        print('Error updating alert for $alertType: $e');
      }
    }

    print("Intervals saved: $_selectedIntervals");
  }

  void _showHardwareKeysDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Hardware Keys'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _items.map((item) {
                  return CheckboxListTile(
                    title: Text(item),
                    value: _selectedItems[item],
                    onChanged: (bool? value) {
                      setState(() {
                        _selectedItems[item] = value!;
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                print('Selected keys:');
                _selectedItems.forEach((key, value) {
                  if (value) {
                    print(key);
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Container(
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
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.green.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings, color: Colors.white, size: 30),
                          const SizedBox(width: 10),
                          Text(
                            'PREFERENCES',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            color: isDarkMode ? Colors.grey.shade700 : Colors
                                .green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: InkWell(
                              onTap: () async {
                                await Future.delayed(
                                    const Duration(milliseconds: 100));
                                _showAlertsDialog(context);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                      Icons.notifications, color: Colors.white),
                                  title: Text(
                                    "Alerts",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            color: isDarkMode ? Colors.grey.shade700 : Colors
                                .green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: InkWell(
                              onTap: () async {
                                await Future.delayed(
                                    const Duration(milliseconds: 100));
                                _showHardwareKeysDialog(
                                    context);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                      Icons.keyboard, color: Colors.white),
                                  title: Text(
                                    "Hardware Keys",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
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
                  Navigator.of(context).pop();
                },
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
