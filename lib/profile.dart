import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User _user;
  DocumentSnapshot? _userData;
  int? _selectedIconIndex;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _fetchUserData(); // Call the method to load the profile data
  }

  // Fetch user profile data from Firestore and update the profileIconIndex
  Future<void> _fetchUserData() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();

      setState(() {
        _userData = snapshot;
        _selectedIconIndex = snapshot.data()?['profileIconIndex'] ?? 1;

        // Convert age to String if it is an integer
        var age = snapshot.data()?['age'];
        if (age is int) {
          age = age.toString();
        }
        _userData = snapshot; // Reassign to avoid type issues
      });
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }


  Future<void> _editProfile() async {
    final TextEditingController firstNameController = TextEditingController(
        text: _userData?.get('firstName') ?? '');
    final TextEditingController lastNameController = TextEditingController(
        text: _userData?.get('lastName') ?? '');
    final TextEditingController emailController = TextEditingController(
        text: _userData?.get('email') ?? '');
    final TextEditingController phoneController = TextEditingController(
        text: (_userData?.get('phone')?.toString() ?? ''));
    final TextEditingController ageController = TextEditingController(
        text: (_userData?.get('age')?.toString() ?? ''));
    final TextEditingController birthdayController = TextEditingController(
        text: _userData?.get('birthday') ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Edit Profile'),
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
                      decoration: InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 8.0),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(labelText: 'Mobile Number'),
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
                    ),
                    SizedBox(height: 10),
                    Text('Select Profile Icon'),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: List.generate(10, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIconIndex =
                                  index; // Update the selected icon index
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: _selectedIconIndex == index ? Colors.blue
                                  .withOpacity(0.2) : Colors.transparent,
                              border: Border.all(
                                color: _selectedIconIndex == index
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: _selectedIconIndex == index ? 3.0 : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(105.0),
                            ),
                            padding: EdgeInsets.all(1.0),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/Icon${index + 1}.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Update Firestore with new profile data and selected icon index
                    await FirebaseFirestore.instance.collection('users').doc(
                        _user.uid).update({
                      'firstName': firstNameController.text,
                      'lastName': lastNameController.text,
                      'email': emailController.text,
                      'phone': phoneController.text,
                      'age': ageController.text,
                      'birthday': birthdayController.text,
                      'profileIconIndex': _selectedIconIndex ?? 0,
                      // Update icon index
                    });

                    // Close the dialog and refresh user data
                    Navigator.of(context).pop();
                    _fetchUserData();
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background container
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'), // Background image
                fit: BoxFit.cover, // Cover the entire container
              ),
            ),
          ),
          // Title at the top
          Positioned(
            top: 80, // Adjust the top position as needed
            left: MediaQuery
                .of(context)
                .size
                .width / 2 - 50, // Center the title horizontally
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // Center the content within the Row
              children: [
                Icon(
                  Icons.person,
                  size: 24, // Adjust the icon size as needed
                  color: Colors.green, // Set the icon color
                ),
                Text(
                  'Profile',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24, // Adjust the font size as needed
                  ),
                ),
                const SizedBox(width: 10),
                // Adds space between the title and the icon
              ],
            ),
          ),
          // Profile details container
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(1),
                  // Slightly transparent green background
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(
                            'assets/images/Icon${_selectedIconIndex != null
                                ? _selectedIconIndex! + 1
                                : 1}.png',
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.blue,
                            radius: 15,
                            child: IconButton(
                              icon: Icon(
                                  Icons.edit, size: 15, color: Colors.white),
                              onPressed: _editProfile,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ProfileItem(
                      icon: Icons.person,
                      label: 'First Name: ${_userData?.get('firstName') ??
                          'Not available'}',
                    ),
                    SizedBox(height: 8.0),
                    ProfileItem(
                      icon: Icons.person_outline,
                      label: 'Last Name: ${_userData?.get('lastName') ??
                          'Not available'}',
                    ),
                    SizedBox(height: 8.0),
                    ProfileItem(
                      icon: Icons.email,
                      label: 'E-mail: ${_userData?.get('email') ??
                          'Not available'}',
                    ),
                    SizedBox(height: 8.0),
                    ProfileItem(
                      icon: Icons.phone,
                      label: 'Mobile Number: ${_userData?.get('phone') ??
                          'Not available'}',
                    ),
                    SizedBox(height: 8.0),
                    ProfileItem(
                      icon: Icons.cake,
                      label: 'Age: ${_userData?.get('age') ?? 'Not available'}',
                    ),
                    SizedBox(height: 8.0),
                    ProfileItem(
                      icon: Icons.calendar_today,
                      label: 'Birthday: ${_userData?.get('birthday') ??
                          'Not available'}',
                    ),
                    SizedBox(height: 8.0),
                    ProfileItem(
                      icon: Icons.person_outline,
                      label: 'User Type: ${_userData?.get('userType') ??
                          'Not available'}',
                    ),
                    SizedBox(height: 8.0),
                  ],
                ),
              ),
            ),
          ),
          // Floating back button positioned at the bottom
          Positioned(
            top: 60, // Adjust this value to move the button down
            left: 16, // Horizontal position
            child: FloatingActionButton(
              mini: true, // Smaller back button
              backgroundColor: Colors.green,
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Navigate back to the previous screen
              },
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

  class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const ProfileItem({
    Key? key,
    required this.icon,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
