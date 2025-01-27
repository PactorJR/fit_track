import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class UsersAdminPage extends StatefulWidget {
  final String? userId;

  UsersAdminPage({this.userId});

  @override
  _UsersAdminPageState createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends State<UsersAdminPage> {
  String? selectedUserId;
  TextEditingController searchController = TextEditingController();
  String searchTerm = '';
  String selectedUserType = 'All';
  bool seen = false;
  String seenValue = 'False';

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
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
          .collection('users')
          .doc(userId)
          .get()
          .then((docSnapshot) {
        if (docSnapshot.exists) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'seen': true});
        } else {
          print("Document with ID $userId not found.");
        }
      }).catchError((error) {
        print("Error checking document: $error");
      });
    } else {
      print("No user selected or user id mismatch");
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
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people,
                  size: 24,
                  color: isDarkMode ? Colors.white : Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  'Users',
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
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(
                      builder: (context) {
                        double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
                        double screenWidth = MediaQuery.of(context).size.width;

                        double borderWidth = (screenWidth <= 320 || devicePixelRatio < 2.0) ? 0.1 : 0.3;
                        double borderHeight = (screenWidth <= 320 || devicePixelRatio < 2.0) ? 0.1 : 0.3;
                        double paddingSize = (screenWidth <= 320 || devicePixelRatio < 2.0) ? 2.0 : 4.0;
                        double fontSize = (screenWidth <= 320 || devicePixelRatio < 2.0) ? 14.0 : 16.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              labelText: 'Search Users',
                              hintText: 'Enter name or email',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  width: borderWidth,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.green,
                                  width: borderWidth,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: borderHeight,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            style: TextStyle(fontSize: fontSize),
                            onChanged: (value) {
                              setState(() {
                                searchTerm = value.toLowerCase();
                              });
                            },
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DropdownButtonFormField<String>(
                        value: selectedUserType,
                        decoration: InputDecoration(
                          labelText: 'Filter by User Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        items: ['All', 'Faculty', 'Student', 'Admin'].map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type,
                              style: TextStyle(
                                color: themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedUserType = newValue!;
                          });
                        },
                      ),
                    ),
                    Container(
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
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Users Information',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
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

                                  var filteredDocs = snapshot.data!.docs.where((doc) {
                                    var name = '${doc['firstName'] ?? ''} ${doc['lastName'] ?? ''}'.toLowerCase();
                                    var email = (doc['email'] ?? '').toLowerCase();
                                    var userType = (doc['userType'] ?? '').toString();

                                    bool matchesSearchTerm = name.contains(searchTerm) || email.contains(searchTerm);
                                    bool matchesUserType = selectedUserType == 'All' || userType == selectedUserType;

                                    return matchesSearchTerm && matchesUserType;
                                  }).toList();

                                  if (filteredDocs.isEmpty) {
                                    return Center(child: Text('No matching users found.'));
                                  }

                                  return Table(
                                    border: TableBorder.all(),
                                    columnWidths: {
                                      0: FixedColumnWidth(100),
                                      1: FixedColumnWidth(120),
                                      2: FixedColumnWidth(110),
                                      3: FixedColumnWidth(50),
                                      4: FixedColumnWidth(90),
                                      5: FixedColumnWidth(90),
                                      6: FixedColumnWidth(80),
                                      7: FixedColumnWidth(50),
                                      8: FixedColumnWidth(70),
                                      9: FixedColumnWidth(90),
                                      10: FixedColumnWidth(120),
                                      11: FixedColumnWidth(50),
                                    },
                                    children: [
                                      TableRow(
                                        children: [
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Age', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Birthday', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('User ID', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('User Type', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Last Login', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Register Time', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: Text('Seen', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      ...filteredDocs.map((doc) {

                                        bool isBanned = doc['userStatus'] == 'Banned';
                                        bool isOnApproval = doc['userStatus'] == 'On Approval';
                                        bool isUnseen = doc['seen'] == false;

                                        Color rowColor = Colors.transparent;

                                        if (isBanned) {
                                          rowColor = Colors.red.withOpacity(0.8);
                                        } else if (isOnApproval) {
                                          rowColor = Colors.yellow.withOpacity(0.8);
                                        } else if (isUnseen) {
                                          rowColor = Colors.yellow.withOpacity(0.8);
                                        }

                                        return TableRow(
                                          decoration: BoxDecoration(
                                            color: selectedUserId == doc.id
                                                ? Colors.green.withOpacity(0.2)
                                                : rowColor,
                                          ),
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);


                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '${doc['firstName'] ?? ''} ${doc['lastName'] ?? ''}',
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);


                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  doc['email'] ?? '',
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);


                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  doc['phone']?.toString() ?? '',
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);


                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  doc['age']?.toString() ?? '',
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);


                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  doc['birthday'] ?? '',
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);


                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  doc['userID'] ?? '',
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);


                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  doc['userType'] ?? '',
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);


                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  doc['wallet']?.toString() ?? '',
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);


                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  doc['userStatus'] ?? '',
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);


                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  doc['lastLogin'] ?? '',
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);


                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  doc['registerTime'] != null
                                                      ? formatTimestamp(doc['registerTime'])
                                                      : '',
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);


                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'seen': true});
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  (doc['seen'] != null) ? (doc['seen'] ? 'True' : 'False') : '',
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                  ),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Builder(
                                  builder: (context) {

                                    double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
                                    double screenWidth = MediaQuery.of(context).size.width;


                                    double fontSize = (screenWidth <= 359 || devicePixelRatio < 2.0) ? 13.0 : 10.0;
                                    double verticalPadding = (screenWidth <= 359 || devicePixelRatio < 2.0) ? 5.0 : 7.0;
                                    double horizontalPadding = (screenWidth <= 359 || devicePixelRatio < 2.0) ? 6.0 : 8.0;

                                    return Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [

                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: verticalPadding,
                                              horizontal: horizontalPadding,
                                            ),
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
                                          SizedBox(width: 16),

                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: verticalPadding,
                                              horizontal: horizontalPadding,
                                            ),
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
                                          SizedBox(width: 16),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: verticalPadding,
                                              horizontal: horizontalPadding,
                                            ),
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
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Builder(
                              builder: (context) {

                                double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
                                double screenWidth = MediaQuery.of(context).size.width;


                                double buttonFontSize = (screenWidth <= 320 || devicePixelRatio < 2.0) ? 12.0 : 14.0;
                                double iconSize = (screenWidth <= 320 || devicePixelRatio < 2.0) ? 20.0 : 24.0;
                                double paddingSize = (screenWidth <= 320 || devicePixelRatio < 2.0) ? 8.0 : 12.0;

                                return Padding(
                                  padding: const EdgeInsets.only(top: 0.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      ElevatedButton(
                                        onPressed: _createUser,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDarkMode ? Colors.white : Colors.white,
                                          padding: EdgeInsets.symmetric(horizontal: paddingSize),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add, color: isDarkMode ? Colors.green : Colors.green, size: iconSize),
                                            SizedBox(width: 8),
                                            Text(
                                              'Create',
                                              style: TextStyle(color: isDarkMode ? Colors.green : Colors.green, fontSize: buttonFontSize),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: selectedUserId?.isNotEmpty ?? false ? () => _editUser(context) : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: selectedUserId?.isNotEmpty ?? false ? (isDarkMode ? Colors.white : Colors.white) : (isDarkMode ? Colors.black.withOpacity(0.7) : Colors.grey.withOpacity(0.7)),
                                          padding: EdgeInsets.symmetric(horizontal: paddingSize),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.edit, color: selectedUserId?.isNotEmpty ?? false ? (isDarkMode ? Colors.blue : Colors.blue) : Colors.blue, size: iconSize),
                                            SizedBox(width: 8),
                                            Text(
                                              'Edit',
                                              style: TextStyle(color: selectedUserId?.isNotEmpty ?? false ? (isDarkMode ? Colors.blue : Colors.blue) : Colors.blue, fontSize: buttonFontSize),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: selectedUserId?.isNotEmpty ?? false ? () => _showDeleteConfirmationDialog(context) : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: selectedUserId?.isNotEmpty ?? false ? Colors.white : Colors.black.withOpacity(0.7),
                                          padding: EdgeInsets.symmetric(horizontal: paddingSize),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.delete, color: Colors.red, size: iconSize),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(color: Colors.red, fontSize: buttonFontSize),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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

          Positioned(
            top: 20,
            left: 16,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: FloatingActionButton(
                mini: true,
                backgroundColor: isDarkMode ? Colors.grey : Colors.green,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _createUser() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateUserDialog();
      },
    );
  }

  void _selectDateAndTime(BuildContext context, TextEditingController controller) async {

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {

      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );

      if (selectedTime != null) {

        final DateTime combinedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );


        String formattedDateTime = "${combinedDateTime.toLocal().year.toString().padLeft(4, '0')}-${(combinedDateTime.month).toString().padLeft(2, '0')}-${(combinedDateTime.day).toString().padLeft(2, '0')} ${combinedDateTime.hour.toString().padLeft(2, '0')}:${combinedDateTime.minute.toString().padLeft(2, '0')}";

        controller.text = formattedDateTime;
      }
    }
  }

  void _editUser(BuildContext context) async {

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isDarkMode = themeProvider.isDarkMode;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(selectedUserId).get();

    final firstNameController = TextEditingController(text: userDoc['firstName']);
    final lastNameController = TextEditingController(text: userDoc['lastName']);
    final emailController = TextEditingController(text: userDoc['email']);
    final phoneController = TextEditingController(text: userDoc['phone']?.toString());
    final ageController = TextEditingController(text: userDoc['age']?.toString());
    final birthdayController = TextEditingController(text: userDoc['birthday']);
    final userTypeController = TextEditingController(text: userDoc['userType']);
    final walletController = TextEditingController(text: userDoc['wallet']?.toString());

    String userStatus = userDoc['userStatus'];
    bool seen = userDoc['seen'];
    String seenValue = seen ? 'True' : 'False';
    Timestamp? registerTime = userDoc['registerTime'];

    final registerTimeController = TextEditingController(text: registerTime != null ? registerTime.toDate().toString().split(' ')[0] : '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          title: Text(
            'Edit User',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(firstNameController, 'First Name', isDarkMode),
                _buildTextField(lastNameController, 'Last Name', isDarkMode),
                _buildTextField(emailController, 'Email', isDarkMode),
                _buildTextField(phoneController, 'Phone', isDarkMode, keyboardType: TextInputType.phone),
                _buildTextField(ageController, 'Age', isDarkMode, keyboardType: TextInputType.number),
                _buildTextField(birthdayController, 'Birthday', isDarkMode, keyboardType: TextInputType.datetime),
                _buildTextField(userTypeController, 'User Type', isDarkMode),
                _buildTextField(walletController, 'Wallet', isDarkMode, keyboardType: TextInputType.number),
                _buildDropdown(userStatus, 'User Status', ['Active', 'On Approval', 'Banned'], isDarkMode, (newValue) {
                  setState(() {
                    userStatus = newValue!;
                  });
                }),
                _buildDatePicker(registerTimeController, 'Register Time', isDarkMode),
                _buildDropdown(seenValue, 'Seen', ['True', 'False'], isDarkMode, (newValue) {
                  setState(() {
                    seen = newValue == 'True';
                  });
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: isDarkMode ? Colors.green : Colors.green)),
            ),
            TextButton(
              onPressed: () async {
                DateTime? parsedRegisterTime = DateTime.tryParse(registerTimeController.text);
                Timestamp? newRegisterTime = parsedRegisterTime != null ? Timestamp.fromDate(parsedRegisterTime) : null;

                await FirebaseFirestore.instance.collection('users').doc(selectedUserId).update({
                  'firstName': firstNameController.text,
                  'lastName': lastNameController.text,
                  'email': emailController.text,
                  'phone': int.tryParse(phoneController.text) ?? 0,
                  'age': int.tryParse(ageController.text) ?? 0,
                  'birthday': birthdayController.text,
                  'userType': userTypeController.text,
                  'wallet': int.tryParse(walletController.text) ?? 0,
                  'userStatus': userStatus,
                  'registerTime': newRegisterTime,
                  'seen': false,
                });

                Navigator.pop(context);
              },
              child: Text('Save', style: TextStyle(color: isDarkMode ? Colors.green : Colors.green)),
            ),
          ],
        );
      },
    );
  }


  Widget _buildTextField(TextEditingController controller, String label, bool isDarkMode, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDropdown(String value, String label, List<String> items, bool isDarkMode, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker(TextEditingController controller, String label, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          _selectDateAndTime(context, controller);
        },
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            keyboardType: TextInputType.datetime,
          ),
        ),
      ),
    );
  }


  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Confirmation'),
          content: Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel',
                  style: TextStyle(color: Colors.green),
              ),
            ),
            TextButton(
              onPressed: () async {

                await FirebaseFirestore.instance.collection('users').doc(selectedUserId).delete();
                Navigator.of(context).pop();
              },
              child: Text('Delete',
                  style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}


class CreateUserDialog extends StatefulWidget {
  @override
  _CreateUserDialogState createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _userIDController = TextEditingController();
  final TextEditingController _walletController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _registerTimeController = TextEditingController();
  bool seen = false;
  String seenValue = 'False';
  String userType = 'Student';

  @override
  void initState() {
    super.initState();
    _fetchUserDoc();
  }


  Future<void> _fetchUserDoc() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc('userID')
        .get();

    if (userDoc.exists) {
      setState(() {
        seen = userDoc['seen'] ?? false;
        seenValue = seen ? 'True' : 'False';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return AlertDialog(
      title: Text('Create User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: 'Age'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _birthdayController,
              decoration: InputDecoration(labelText: 'Birthday'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _userIDController,
              decoration: InputDecoration(labelText: 'User ID'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _walletController,
              decoration: InputDecoration(labelText: 'Wallet'),
            ),
            SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              value: userType,
              items: [
                DropdownMenuItem(
                  value: 'Student',
                  child: Text('Student', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black,)),
                ),
                DropdownMenuItem(
                  value: 'Faculty',
                  child: Text('Faculty', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black,)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  userType = value!;
                });
              },
              decoration: InputDecoration(labelText: 'User Type'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 8.0),
            GestureDetector(
              onTap: () {
                _selectDateAndTime(context, _registerTimeController);
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: _registerTimeController,
                  decoration: InputDecoration(labelText: 'Register Time'),
                  keyboardType: TextInputType.datetime,
                ),
              ),
            ),
            SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              value: seenValue,
              items: [
                DropdownMenuItem(value: 'True', child: Text('True', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black,)),
                ),
                DropdownMenuItem(value: 'False', child: Text('False', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black,)),
                ),
              ],
              onChanged: (value) {
                setState(() {

                  seen = value == 'True';

                });
              },
              decoration: InputDecoration(labelText: 'Seen'),
            ),
            SizedBox(height: 8.0),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.green),
          ),
        ),
        TextButton(
          onPressed: _saveUser,
          child: Text(
            'Create',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }


  void _selectDateAndTime(BuildContext context, TextEditingController controller) async {

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {

      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );

      if (selectedTime != null) {

        final DateTime combinedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );


        String formattedDateTime = "${combinedDateTime.toLocal().year.toString().padLeft(4, '0')}-${(combinedDateTime.month).toString().padLeft(2, '0')}-${(combinedDateTime.day).toString().padLeft(2, '0')} ${combinedDateTime.hour.toString().padLeft(2, '0')}:${combinedDateTime.minute.toString().padLeft(2, '0')}";
        controller.text = formattedDateTime;
      }
    }
  }


  void _saveUser() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String age = _ageController.text.trim();
    String birthday = _birthdayController.text.trim();
    String userID = _userIDController.text.trim();
    String wallet = _walletController.text.trim();
    String password = _passwordController.text.trim();
    String registerTimeString = _registerTimeController.text.trim();
    DateTime registerTimeDateTime = DateTime.parse(registerTimeString);
    Timestamp registerTimeTimestamp = Timestamp.fromDate(registerTimeDateTime);

    if (firstName.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').add({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'age': age,
        'birthday': birthday,
        'userID': userID,
        'userType': userType,
        'wallet': wallet,
        'userStatus': 'Active',
        'lastLogin': DateTime.now().toIso8601String(),
        'registerTime': FieldValue.serverTimestamp(),
        'seen': seen,
      });

      Navigator.of(context).pop();
    }
  }
}


