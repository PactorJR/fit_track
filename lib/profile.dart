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
import 'package:path/path.dart';


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
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _isLoading = true;

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    _fetchUserData();
    checkAndAddProfileImage();
    try {
      await Future.wait([
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


  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    checkAndAddProfileImage();
    _fetchUserData();
  }

  void checkAndAddProfileImage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();


        var userData = userDoc.data() as Map<String, dynamic>?;
        if (userData == null || !userData.containsKey('profileImage')) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({'profileImage': null});
        }
      } catch (e) {

        print("Error checking/updating profile image: $e");
      }
    }
  }



  Future<void> _fetchUserData() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();

      setState(() {
        _userData = snapshot;
        _selectedIconIndex = snapshot.data()?['profileIconIndex'] ?? 1;

        var age = snapshot.data()?['age'];
        if (age is int) {
          age = age.toString();
        }
        _userData = snapshot;
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
                              selectedImage = null;
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
                            _selectedIconIndex = null;
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
                    Map<String, dynamic> updates = {
                      'firstName': firstNameController.text,
                      'lastName': lastNameController.text,
                      'phone': phoneController.text,
                      'age': ageController.text,
                      'birthday': birthdayController.text,
                    };

                    if (selectedImage != null) {
                      File imageFile = File(selectedImage!.path);
                      String filePath = 'userProfiles/${_user.uid}/${basename(
                          selectedImage!.path)}';
                      TaskSnapshot uploadTask = await FirebaseStorage.instance
                          .ref(filePath)
                          .putFile(imageFile);
                      String downloadURL = await uploadTask.ref
                          .getDownloadURL();

                      updates['profileImage'] = downloadURL;
                      updates['profileIconIndex'] = 0;
                    } else if (_selectedIconIndex != null) {
                      updates['profileIconIndex'] = _selectedIconIndex;
                      updates['profileImage'] = null;
                    }

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user.uid)
                        .update(updates);

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

  Future<bool> showChangePasswordDialog(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isDarkMode = themeProvider.isDarkMode;

    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    User? user = FirebaseAuth.instance.currentUser;

    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.white : Colors.white,
          title: Text(
            'Change Password',
            style: TextStyle(color: isDarkMode ? Colors.black : Colors.green),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.black : Colors.black),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: isDarkMode ? Colors.black : Colors.black),
              ),
              SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.black : Colors.black),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: isDarkMode ? Colors.black : Colors.black),
              ),
              SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.black : Colors.black),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: isDarkMode ? Colors.black : Colors.black),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDarkMode ? Colors.green : Colors.green),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.green : Colors.green,
              ),
              onPressed: () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('New passwords do not match!')),
                  );
                  return;
                }

                try {
                  AuthCredential credential = EmailAuthProvider.credential(
                    email: user!.email!,
                    password: currentPasswordController.text.trim(),
                  );
                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPasswordController.text.trim());

                  Navigator.pop(context, true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password changed successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: Text('Change Password', style: TextStyle(color: isDarkMode ? Colors.black : Colors.white)),
            ),
          ],
        );
      },
    ) ??
        false;
  }


  Future<bool> showChangeEmailDialog(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isDarkMode = themeProvider.isDarkMode;

    TextEditingController currentEmailController = TextEditingController();
    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newEmailController = TextEditingController();

    User? user = FirebaseAuth.instance.currentUser;

    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          title: Text(
            'Change Email',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.green),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Current Email Address',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              SizedBox(height: 10),
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              SizedBox(height: 10),
              TextField(
                controller: newEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'New Email Address',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDarkMode ? Colors.green : Colors.green),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.green : Colors.green,
              ),
              onPressed: () async {
                if (currentEmailController.text.isEmpty ||
                    currentPasswordController.text.isEmpty ||
                    newEmailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in all fields!')),
                  );
                  return;
                }

                try {
                  AuthCredential credential = EmailAuthProvider.credential(
                    email: currentEmailController.text.trim(),
                    password: currentPasswordController.text.trim(),
                  );
                  await user!.reauthenticateWithCredential(credential);

                  await user.updateEmail(newEmailController.text.trim());

                  Navigator.pop(context, true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Email changed successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: Text('Change Email', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    double screenWidth = MediaQuery.of(context).size.width;

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
                  Icons.person,
                  size: screenWidth <= 409 ? 24 : 30,
                  color: isDarkMode ? Colors.white : Colors.green,
                ),
                Text(
                  'Profile',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth <= 409 ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 200.0),
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black38 : Colors.green.shade800
                            .withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: screenWidth <= 409 ? 30 : 40,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _image != null
                                    ? FileImage(File(_image!.path))
                                    : (_userData?.get('profileImage') != null &&
                                    _userData!.get('profileImage').isNotEmpty
                                    ? NetworkImage(_userData!.get('profileImage'))
                                    : AssetImage(
                                    'assets/images/Icon${_selectedIconIndex != null ? _selectedIconIndex! + 1 : 1}.png')
                                as ImageProvider),
                                child: null,
                              ),
                              Positioned(
                                bottom: screenWidth <= 409 ? 0 : 0,
                                right: screenWidth <= 409 ? 0 : 0,
                                child: CircleAvatar(
                                  backgroundColor: isDarkMode ? Colors.black : Colors.green.shade800,
                                  radius: screenWidth <= 409 ? 15 : 18,
                                  child: IconButton(
                                    icon: Icon(Icons.edit, size: screenWidth <= 409 ? 15 : 20,
                                        color: Colors.white),
                                    onPressed: () {
                                      _editProfile(context);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          ProfileItem(
                            icon: Icons.person,
                            label: 'First Name: ${_userData?.get('firstName') ?? 'Not available'}',
                          ),
                          SizedBox(height: screenWidth <= 409 ? 8 : 10),
                          ProfileItem(
                            icon: Icons.person_outline,
                            label: 'Last Name: ${_userData?.get('lastName') ?? 'Not available'}',
                          ),
                          SizedBox(height: screenWidth <= 409 ? 8 : 10),
                          ProfileItem(
                            icon: Icons.email,
                            label: 'Email: ${_userData?.get('email') ?? 'Not available'}',
                          ),
                          SizedBox(height: screenWidth <= 409 ? 8 : 10),
                          ProfileItem(
                            icon: Icons.phone,
                            label: 'Mobile Number: ${_userData?.get('phone') ?? 'Not available'}',
                          ),
                          SizedBox(height: screenWidth <= 409 ? 8 : 10),
                          ProfileItem(
                            icon: Icons.cake,
                            label: 'Birthday: ${_userData?.get('birthday') ?? 'Not available'}',
                          ),
                          SizedBox(height: screenWidth <= 409 ? 8 : 10),
                          ProfileItem(
                            icon: Icons.timer,
                            label: 'Age: ${_userData?.get('age') ?? 'Not available'}',
                          ),
                          SizedBox(height: screenWidth <= 409 ? 8 : 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                width: 140,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showChangePasswordDialog(context);
                                  },
                                  icon: Icon(Icons.lock, size: 18),
                                  label: Text('Password', style: TextStyle(fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode ? Colors.grey : Colors.green.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              SizedBox(
                                width: 140,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showChangeEmailDialog(context);
                                  },
                                  icon: Icon(Icons.email, size: 18),
                                  label: Text('Email', style: TextStyle(fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode ? Colors.grey.shade400 : Colors.green.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenWidth <= 409 ? 60 : 80),
                        ],
                      ),
                    ),
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
                backgroundColor: Theme
                    .of(context)
                    .brightness == Brightness.dark
                    ? Colors.grey
                    : Colors.green,
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

    double screenWidth = MediaQuery.of(context).size.width;
    double otherFontSize = screenWidth <= 409 ? 15 : 20;
    double iconSize = screenWidth <= 409 ? 15 : 20;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: iconSize),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: otherFontSize,
            ),
          ),
        ],
      ),
    );
  }
}
