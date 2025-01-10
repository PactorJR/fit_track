import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart'; // For handling file paths


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
  final ImagePicker _picker = ImagePicker();  // Declare ImagePicker instance
  XFile? _image;  // Declare _image for storing picked image

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


  Future<void> _editProfile(BuildContext context) async {
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

    XFile? selectedImage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                              _selectedIconIndex = index;
                              selectedImage = null; // Reset custom image preview
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: _selectedIconIndex == index && selectedImage == null
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: _selectedIconIndex == index && selectedImage == null
                                    ? Colors.green
                                    : Colors.transparent,
                                width: _selectedIconIndex == index && selectedImage == null
                                    ? 3.0
                                    : 1.0,
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
                    SizedBox(height: 10),
                    Text('Upload Profile Picture'),
                    selectedImage != null
                        ? ClipOval(
                      child: Image.file(
                        File(selectedImage!.path),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                        : SizedBox(),
                    ElevatedButton(
                      onPressed: () async {
                        selectedImage = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                          maxWidth: 800,
                          maxHeight: 800,
                        );
                        if (selectedImage != null) {
                          setState(() {
                            _selectedIconIndex = null; // Reset selected icon
                          });
                        }
                      },
                      child: Text('Pick Image'),
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
                    // Prepare updates map
                    Map<String, dynamic> updates = {
                      'firstName': firstNameController.text,
                      'lastName': lastNameController.text,
                      'email': emailController.text,
                      'phone': phoneController.text,
                      'age': ageController.text,
                      'birthday': birthdayController.text,
                    };

                    if (selectedImage != null) {
                      // User has uploaded an image
                      File imageFile = File(selectedImage!.path);
                      String filePath = 'userProfiles/${_user.uid}/${basename(selectedImage!.path)}';
                      TaskSnapshot uploadTask = await FirebaseStorage.instance
                          .ref(filePath)
                          .putFile(imageFile);
                      String downloadURL = await uploadTask.ref.getDownloadURL();

                      // Update Firestore with the uploaded image
                      updates['profileImage'] = downloadURL;
                      updates['profileIconIndex'] = 0; // Reset icon index
                    } else if (_selectedIconIndex != null) {
                      // User has selected a profile icon
                      updates['profileIconIndex'] = _selectedIconIndex;
                      updates['profileImage'] = null; // Clear image
                    }

                    // Save updates to Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user.uid)
                        .update(updates);

                    Navigator.of(context).pop();
                    _fetchUserData(); // Refresh user data
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    return Scaffold(
      body: Stack(
        children: [
          // Background container
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
                  color: Provider.of<ThemeProvider>(context).isDarkMode ? Colors.white : Colors.green,
                ),
                Text(
                  'Profile',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
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
                  color: Provider.of<ThemeProvider>(context).isDarkMode
                      ? Colors.black38
                      : Colors.green.shade800,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200], // Fallback background color
                          backgroundImage: _image != null
                              ? FileImage(File(_image!.path)) // Use FileImage for local file paths
                              : (_userData?.get('profileImage') != null && _userData!.get('profileImage').isNotEmpty
                              ? NetworkImage(_userData!.get('profileImage')) // Use NetworkImage for Firebase URL
                              : AssetImage('assets/images/Icon${_selectedIconIndex != null ? _selectedIconIndex! + 1 : 1}.png') as ImageProvider),
                          child: null, // No child, remove fallback icon
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
                                ? Colors.black
                                : Colors.green.shade800,
                            radius: 15,
                            child: IconButton(
                              icon: Icon(Icons.edit, size: 15, color: Colors.white),
                              onPressed: () {
                                _editProfile(context); // Trigger profile editing dialog
                              },
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
              backgroundColor: isDarkMode ? Colors.grey : Colors.green,
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
