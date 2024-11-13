import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: UsersAdminPage(),
    );
  }
}

class UsersAdminPage extends StatefulWidget {
  @override
  _UsersAdminPageState createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends State<UsersAdminPage> {
  String? selectedUserId;
  TextEditingController searchController = TextEditingController();
  String searchTerm = '';
  String selectedUserType = 'All'; // Add this to store the selected user type for sorting

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'), // Background image
                fit: BoxFit.cover, // Cover the entire background
              ),
            ),
          ),
          // Foreground content
          Padding(
            padding: const EdgeInsets.all(16.0), // Adjust the padding as needed
            child: Column(
              children: [
                // Search bar
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
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedUserType = newValue!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8), // Green-colored container with opacity
                      borderRadius: BorderRadius.circular(16.0), // Rounded edges
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0), // Padding inside the container
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Make column take minimum space
                        crossAxisAlignment: CrossAxisAlignment.center, // Center the title
                        children: [
                          Text(
                            'Users Information',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center, // Center text
                          ),
                          SizedBox(height: 8), // Space between title and table
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal, // Allow horizontal scrolling
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

                                // Filtering users by search term and user type
                                var filteredDocs = snapshot.data!.docs.where((doc) {
                                  var name = '${doc['firstName'] ?? ''} ${doc['lastName'] ?? ''}'.toLowerCase();
                                  var email = (doc['email'] ?? '').toLowerCase();
                                  var userType = (doc['userType'] ?? '').toString();

                                  // Check if it matches the search term
                                  bool matchesSearchTerm = name.contains(searchTerm) || email.contains(searchTerm);

                                  // Check if it matches the selected user type (if not 'All')
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
                                      ],
                                    ),
                                    ...filteredDocs.map((doc) {
                                      bool isOnApproval = doc['userStatus'] == 'On Approval'; // Check user status
                                      Color textColor = isOnApproval ? Colors.red : Colors.black; // Set color based on status

                                      return TableRow(
                                        decoration: BoxDecoration(
                                          color: selectedUserId == doc.id ? Colors.blue.withOpacity(0.3) : Colors.transparent, // Highlight selected user
                                        ),
                                        children: [
                                          GestureDetector(
                                            onTap: () => _selectUser(doc.id),
                                            child: Container(
                                              height: 40,
                                              alignment: Alignment.center,
                                              child: Text('${doc['firstName'] ?? ''} ${doc['lastName'] ?? ''}', style: TextStyle(color: textColor)),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _selectUser(doc.id),
                                            child: Container(
                                              height: 40,
                                              alignment: Alignment.center,
                                              child: Text(doc['email'] ?? '', style: TextStyle(color: textColor)),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _selectUser(doc.id),
                                            child: Container(
                                              height: 40,
                                              alignment: Alignment.center,
                                              child: Text(doc['phone']?.toString() ?? '', style: TextStyle(color: textColor)),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _selectUser(doc.id),
                                            child: Container(
                                              height: 40,
                                              alignment: Alignment.center,
                                              child: Text(doc['age']?.toString() ?? '', style: TextStyle(color: textColor)),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _selectUser(doc.id),
                                            child: Container(
                                              height: 40,
                                              alignment: Alignment.center,
                                              child: Text(doc['birthday'] ?? '', style: TextStyle(color: textColor)),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _selectUser(doc.id),
                                            child: Container(
                                              height: 40,
                                              alignment: Alignment.center,
                                              child: Text(doc['userID'] ?? '', style: TextStyle(color: textColor)),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _selectUser(doc.id),
                                            child: Container(
                                              height: 40,
                                              alignment: Alignment.center,
                                              child: Text(doc['userType'] ?? '', style: TextStyle(color: textColor)),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _selectUser(doc.id),
                                            child: Container(
                                              height: 40,
                                              alignment: Alignment.center,
                                              child: Text(doc['wallet']?.toString() ?? '', style: TextStyle(color: textColor)),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _selectUser(doc.id),
                                            child: Container(
                                              height: 40,
                                              alignment: Alignment.center,
                                              child: Text(doc['userStatus'] ?? '', style: TextStyle(color: textColor)),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _selectUser(doc.id),
                                            child: Container(
                                              height: 40,
                                              alignment: Alignment.center,
                                              child: Text(doc['lastLogin'] ?? '', style: TextStyle(color: textColor)),
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
                          SizedBox(height: 16), // Space between table and buttons
                          Padding(
                            padding: const EdgeInsets.only(top: 0.0), // Adjust the padding as needed
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround, // Space buttons evenly
                              children: [
                                ElevatedButton(
                                  onPressed: _createUser, // Create new user button
                                  child: Text('Create'),
                                ),
                                ElevatedButton(
                                  onPressed: selectedUserId != null ? () => _readUser(context) : null, // Disable if no user selected
                                  child: Text('Read'),
                                ),
                                ElevatedButton(
                                  onPressed: selectedUserId != null ? () => _editUser(context) : null, // Disable if no user selected
                                  child: Text('Update'),
                                ),
                                ElevatedButton(
                                  onPressed: selectedUserId != null ? () => _showDeleteConfirmationDialog(context) : null, // Disable if no user selected
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectUser(String userId) {
    setState(() {
      selectedUserId = userId;
    });
  }


  // Read functionality to display user info in a dialog
  void _readUser(BuildContext context) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(selectedUserId).get();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${userDoc['firstName']} ${userDoc['lastName']}'),
              Text('Email: ${userDoc['email']}'),
              Text('Phone: ${userDoc['phone']}'),
              Text('Age: ${userDoc['age']}'),
              Text('Birthday: ${userDoc['birthday']}'),
              Text('User Type: ${userDoc['userType']}'),
              Text('Wallet: ${userDoc['wallet']}'),
              // Add more fields if needed
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
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

  // Edit functionality
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
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: 'Last Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: ageController,
                  decoration: InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: birthdayController,
                  decoration: InputDecoration(labelText: 'Birthday'),
                  keyboardType: TextInputType.datetime,
                ),
                TextField(
                  controller: userTypeController,
                  decoration: InputDecoration(labelText: 'User Type'),
                ),
                TextField(
                  controller: walletController,
                  decoration: InputDecoration(labelText: 'Wallet'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: userStatus,
                  decoration: InputDecoration(labelText: 'User Status'),
                  items: ['Active', 'On Approval'].map((String status) {
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
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
                });

                Navigator.pop(context);
              },
              child: Text('Save'),
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
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Perform the delete operation
                await FirebaseFirestore.instance.collection('users').doc(selectedUserId).delete();
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}


// Separate dialog for creating new user
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

  String userType = 'Student'; // Default user type

  @override
  Widget build(BuildContext context) {
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
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: 'Age'),
            ),
            TextField(
              controller: _birthdayController,
              decoration: InputDecoration(labelText: 'Birthday'),
            ),
            TextField(
              controller: _userIDController,
              decoration: InputDecoration(labelText: 'User ID'),
            ),
            TextField(
              controller: _walletController,
              decoration: InputDecoration(labelText: 'Wallet'),
            ),
            DropdownButtonFormField<String>(
              value: userType,
              items: [
                DropdownMenuItem(value: 'Student', child: Text('Student')),
                DropdownMenuItem(value: 'Faculty', child: Text('Faculty')),
              ],
              onChanged: (value) {
                setState(() {
                  userType = value!;
                });
              },
              decoration: InputDecoration(labelText: 'User Type'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true, // Hide password text
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveUser,
          child: Text('Create'),
        ),
      ],
    );
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
      });

      // After saving, you can add the user to Firebase Authentication as well
      Navigator.of(context).pop(); // Close the dialog after saving
    }
  }
}
