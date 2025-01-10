import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class UsersAdminPage extends StatefulWidget {
  final String? userId;  // Make userId nullable (optional)

  // Constructor with an optional userId, defaults to null if not provided
  UsersAdminPage({this.userId});

  @override
  _UsersAdminPageState createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends State<UsersAdminPage> {
  String? selectedUserId;
  TextEditingController searchController = TextEditingController();
  String searchTerm = '';
  String selectedUserType = 'All'; // Add this to store the selected user type for sorting
  bool seen = false;  // Initialize to a default value
  String seenValue = 'False';  // Set to default 'False' initially

  String formatTimestamp(Timestamp timestamp) {
    // Convert Timestamp to DateTime and format it as a String
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);  // Adjust the format as needed
  }

  @override
  void initState() {
    super.initState();

    // Set selectedUserId to the userId if it's not null, or use a default value if null
    selectedUserId = widget.userId ?? null; // This makes userId optional
    if (selectedUserId != null) {
      _selectUser(selectedUserId!); // Proceed only if userId is not null
    }
  }

  void _selectUser(String userId) {
    setState(() {
      selectedUserId = userId;
    });

    // Only update the 'seen' field if selectedUserId is not null and matches the doc.id
    if (selectedUserId != null && selectedUserId == userId) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()  // Fetch the document first to check if it exists
          .then((docSnapshot) {
        if (docSnapshot.exists) {
          // Document exists, so proceed with the update
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'seen': true});
        } else {
          // Document does not exist, handle the error or log it
          print("Document with ID $userId not found.");
        }
      }).catchError((error) {
        // Handle any potential errors
        print("Error checking document: $error");
      });
    } else {
      // Optionally handle cases where selectedUserId is null or doesn't match
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
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isDarkMode
                      ? 'assets/images/dark_bg.png'
                      : 'assets/images/bg.png', // Switch background image based on dark mode
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Title at the top
          Positioned(
            top: 100,
            left: 0,
            right: 0,
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
          // Foreground content centered
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 600),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Search Users',
                          hintText: 'Enter name or email',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green, width: 2.0),  // Green border when focused
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2.0),  // Red border when focused and error occurs
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchTerm = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    // Dropdown for sorting by user type
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
                                          ? Colors.white // Black for dark mode
                                          : Colors.black, // Green for light mode
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
                        color: themeProvider.isDarkMode
                            ? Colors.black38 // Black for dark mode
                            : Colors.green.withOpacity(0.8), // Green for light mode
                        borderRadius: BorderRadius.circular(16.0),
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
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black, // Dynamic color
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
                                        // Determine the background color based on the user status
                                        bool isBanned = doc['userStatus'] == 'Banned';
                                        bool isOnApproval = doc['userStatus'] == 'On Approval';
                                        bool isUnseen = doc['seen'] == false;

                                        Color rowColor = Colors.transparent; // Default row color

                                        if (isBanned) {
                                          rowColor = Colors.red.withOpacity(0.8); // Light red for banned users
                                        } else if (isOnApproval) {
                                          rowColor = Colors.blue.withOpacity(0.8); // Light blue for users on approval
                                        } else if (isUnseen) {
                                          rowColor = Colors.yellow.withOpacity(0.8); // Light yellow for unseen users
                                        }

                                        return TableRow(
                                          decoration: BoxDecoration(
                                            color: selectedUserId == doc.id
                                                ? Colors.white.withOpacity(0.8) // Highlight selected row
                                                : rowColor, // Apply dynamic row color
                                          ),
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                _selectUser(doc.id);

                                                // Update the 'seen' field to true when the row is selected
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

                                                // Update the 'seen' field to true when the row is selected
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

                                                // Update the 'seen' field to true when the row is selected
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

                                                // Update the 'seen' field to true when the row is selected
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

                                                // Update the 'seen' field to true when the row is selected
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

                                                // Update the 'seen' field to true when the row is selected
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

                                                // Update the 'seen' field to true when the row is selected
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

                                                // Update the 'seen' field to true when the row is selected
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

                                                // Update the 'seen' field to true when the row is selected
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

                                                // Update the 'seen' field to true when the row is selected
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

                                                // Update the 'seen' field to true when the row is selected
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

                                                // Update the 'seen' field to true when the row is selected
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
                            SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(top: 0.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  ElevatedButton(
                                    onPressed: _createUser, // Disable if selectedUserId is empty or null
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDarkMode ? Colors.white : Colors.white, // Set the background color
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min, // Ensure the button size adjusts to its content
                                      children: [
                                        Icon(Icons.add, color: isDarkMode ? Colors.green : Colors.green,), // Change icon color to white to contrast with the green background
                                        SizedBox(width: 8), // Add spacing between the icon and the text
                                        Text(
                                          'Create',
                                          style: TextStyle(color: isDarkMode ? Colors.green : Colors.green,), // Change text color to white for visibility on green
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: selectedUserId?.isNotEmpty ?? false ? () => _editUser(context) : null, // Disable if selectedUserId is empty or null
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: selectedUserId?.isNotEmpty ?? false ? Colors.white : Colors.black.withOpacity(0.7), // Set background color based on selectedUserId
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit, color: selectedUserId?.isNotEmpty ?? false ? Colors.blue : Colors.blue), // Change icon color based on selectedUserId
                                        SizedBox(width: 8),
                                        Text(
                                          'Edit',
                                          style: TextStyle(color: selectedUserId?.isNotEmpty ?? false ? Colors.blue : Colors.blue), // Change text color based on selectedUserId
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: selectedUserId?.isNotEmpty ?? false ? () => _showDeleteConfirmationDialog(context) : null, // Disable if selectedUserId is empty or null
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: selectedUserId?.isNotEmpty ?? false ? Colors.white : Colors.black.withOpacity(0.7), // Set background color based on selectedUserId
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
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
          // Positioned button at the top left
          Positioned(
            top: 20,
            left: 16,
            child: Padding(
              padding: const EdgeInsets.all(6.0),  // Add padding here
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

  // Create functionality
  void _createUser() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateUserDialog();
      },
    );
  }

  void _selectDateAndTime(BuildContext context, TextEditingController controller) async {
    // Show date picker first
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      // Show time picker if a date was selected
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()), // Set current time as default
      );

      if (selectedTime != null) {
        // Combine selected date and time
        final DateTime combinedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        // Format the combined date and time as "yyyy-MM-dd HH:mm"
        String formattedDateTime = "${combinedDateTime.toLocal().year.toString().padLeft(4, '0')}-${(combinedDateTime.month).toString().padLeft(2, '0')}-${(combinedDateTime.day).toString().padLeft(2, '0')} ${combinedDateTime.hour.toString().padLeft(2, '0')}:${combinedDateTime.minute.toString().padLeft(2, '0')}";

        controller.text = formattedDateTime;
      }
    }
  }

  void _editUser(BuildContext context) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(selectedUserId).get();

    final firstNameController = TextEditingController(text: userDoc['firstName']);
    final lastNameController = TextEditingController(text: userDoc['lastName']);
    final emailController = TextEditingController(text: userDoc['email']);
    final phoneController = TextEditingController(text: userDoc['phone']?.toString());
    final ageController = TextEditingController(text: userDoc['age']?.toString());
    final birthdayController = TextEditingController(text: userDoc['birthday']);
    final userTypeController = TextEditingController(text: userDoc['userType']);
    final walletController = TextEditingController(text: userDoc['wallet']?.toString());
    String userStatus = userDoc['userStatus']; // Store current user status
    bool seen = userDoc['seen']; // get the boolean value
    String seenValue = seen ? 'True' : 'False'; // convert to 'True' or 'False'
    Timestamp? registerTime = userDoc['registerTime']; // Store the Timestamp value

    final registerTimeController = TextEditingController(text: registerTime != null ? registerTime.toDate().toString().split(' ')[0] : ''); // Convert to DateTime string if available

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(labelText: 'First Name'),
                ),
                SizedBox(height: 8.0),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: 'Last Name'),
                ),
                SizedBox(height: 8.0),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                SizedBox(height: 8.0),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 8.0),
                TextField(
                  controller: ageController,
                  decoration: InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8.0),
                TextField(
                  controller: birthdayController,
                  decoration: InputDecoration(labelText: 'Birthday'),
                  keyboardType: TextInputType.datetime,
                ),
                SizedBox(height: 8.0),
                TextField(
                  controller: userTypeController,
                  decoration: InputDecoration(labelText: 'User Type'),
                ),
                SizedBox(height: 8.0),
                TextField(
                  controller: walletController,
                  decoration: InputDecoration(labelText: 'Wallet'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8.0),
                DropdownButtonFormField<String>(
                  value: userStatus,
                  decoration: InputDecoration(labelText: 'User Status'),
                  items: ['Active', 'On Approval', 'Banned'].map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      userStatus = newValue!;
                    });
                  },
                ),
                SizedBox(height: 8.0),
                GestureDetector(
                  onTap: () {
                    _selectDateAndTime(context, registerTimeController); // Open both date and time pickers
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: registerTimeController,
                      decoration: InputDecoration(labelText: 'Register Time'),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
                DropdownButtonFormField<String>(
                  value: seenValue, // use the string value 'True' or 'False'
                  decoration: InputDecoration(labelText: 'Seen'),
                  items: ['True', 'False'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      // Update the 'seen' value as boolean based on dropdown selection
                      seen = newValue == 'True'; // Convert the selected value back to bool
                    });
                  },
                ),
                SizedBox(height: 8.0),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () async {
                // Parse the registerTime from the text input field and convert it to a Timestamp
                DateTime? parsedRegisterTime = DateTime.tryParse(registerTimeController.text);
                Timestamp? newRegisterTime = parsedRegisterTime != null ? Timestamp.fromDate(parsedRegisterTime) : null;

                // Update the user's data in Firestore
                await FirebaseFirestore.instance.collection('users').doc(selectedUserId).update({
                  'firstName': firstNameController.text,
                  'lastName': lastNameController.text,
                  'email': emailController.text,
                  'phone': int.tryParse(phoneController.text) ?? 0,
                  'age': int.tryParse(ageController.text) ?? 0,
                  'birthday': birthdayController.text,
                  'userType': userTypeController.text,
                  'wallet': int.tryParse(walletController.text) ?? 0,
                  'userStatus': userStatus, // Use selected status
                  'registerTime': newRegisterTime, // Update with the new registerTime
                  'seen': false,
                });

                Navigator.pop(context);
              },
              child: Text('Save', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  // Delete functionality
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
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel',
                  style: TextStyle(color: Colors.green),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Perform the delete operation
                await FirebaseFirestore.instance.collection('users').doc(selectedUserId).delete();
                Navigator.of(context).pop(); // Close the dialog after deletion
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
  bool seen = false; // Default value
  String seenValue = 'False'; // Default value for dropdown

  String userType = 'Student'; // Default user type

  @override
  void initState() {
    super.initState();
    _fetchUserDoc();
  }

  // Async method to fetch user document from Firestore
  Future<void> _fetchUserDoc() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc('userID') // Replace with actual user ID
        .get();

    if (userDoc.exists) {
      setState(() {
        seen = userDoc['seen'] ?? false;
        seenValue = seen ? 'True' : 'False'; // Set the string value for dropdown
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
              obscureText: true, // Hide password text
            ),
            SizedBox(height: 8.0),
            GestureDetector(
              onTap: () {
                _selectDateAndTime(context, _registerTimeController); // Open both date and time pickers
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
              value: seenValue, // Set the value to 'True' or 'False' string
              items: [
                DropdownMenuItem(value: 'True', child: Text('True', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black,)),
                ),
                DropdownMenuItem(value: 'False', child: Text('False', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black,)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  // Convert the selected string value back to a boolean
                  seen = value == 'True'; // 'True' -> true, 'False' -> false
                  // Update your Firestore document with the new 'seen' value (if necessary)
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
            Navigator.of(context).pop(); // Close the dialog
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

  // Function to handle date and time selection
  void _selectDateAndTime(BuildContext context, TextEditingController controller) async {
    // Show date picker first
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      // Show time picker if a date was selected
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()), // Set current time as default
      );

      if (selectedTime != null) {
        // Combine selected date and time
        final DateTime combinedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        // Format the combined date and time as "yyyy-MM-dd HH:mm"
        String formattedDateTime = "${combinedDateTime.toLocal().year.toString().padLeft(4, '0')}-${(combinedDateTime.month).toString().padLeft(2, '0')}-${(combinedDateTime.day).toString().padLeft(2, '0')} ${combinedDateTime.hour.toString().padLeft(2, '0')}:${combinedDateTime.minute.toString().padLeft(2, '0')}";
        controller.text = formattedDateTime;
      }
    }
  }

  // Save user function
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
    DateTime registerTimeDateTime = DateTime.parse(registerTimeString); // Parse the string to DateTime
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
        'userStatus': 'Active', // Default status
        'lastLogin': DateTime.now().toIso8601String(),
        'registerTime': FieldValue.serverTimestamp(),
        'seen': seen, // Correctly store the 'seen' value
      });

      Navigator.of(context).pop(); // Close the dialog after saving
    }
  }
}


