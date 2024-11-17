import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack CCAT',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const RegisterPage(),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _userIDController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String errorMessage = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _selectedUserType; // Track selected user type

  PlatformFile? _selectedFile;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      final formattedDate = "${selectedDate.toLocal()}".split(' ')[0]; // Format as yyyy-mm-dd
      _birthdayController.text = formattedDate;
    }
  }
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true, // Ensure the file's bytes are included
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
        print('File selected: ${_selectedFile!.name}, size: ${_selectedFile!.size}');
        print('File bytes length: ${_selectedFile!.bytes?.length}'); // Check if the file has bytes
      } else {
        print('No file selected');
        _selectedFile = null;
      }
    } catch (e) {
      print('File picker failed: $e');
    }
  }

  Future<String?> _uploadFile(String userId) async {

    try {
      // Add more logging to trace the issue
      print('Uploading file: ${_selectedFile!.name}');
      print('File bytes length: ${_selectedFile!.bytes?.length}');

      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('enrollment_certificates/$userId/${_selectedFile!.name}');

      // Check if file bytes are still null here
      if (_selectedFile!.bytes == null) {
        print('File bytes are null, cannot upload.');
        return null;
      }

      UploadTask uploadTask = ref.putData(_selectedFile!.bytes!); // Upload the file bytes

      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('File upload failed: $e');
      return null;
    }
    }

  Future<void> register() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    if (_formKey.currentState?.validate() != true) {
      setState(() {
        errorMessage = 'Please fill out all required fields.';
      });
      return;
    }

    if (_selectedUserType == 'Student' && _selectedFile == null) {
      setState(() {
        errorMessage = 'Please upload the certificate of enrollment.';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        errorMessage = 'Passwords do not match';
      });
      return;
    }

    try {
      if (_userIDController.text.isEmpty) {
        setState(() {
          errorMessage = 'User ID cannot be empty';
        });
        return;
      }
      QuerySnapshot existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('userID', isEqualTo: _userIDController.text)
          .get();

      if (existingUser.docs.isNotEmpty) {
        // Show account exists dialog if found
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Account Already Exists'),
              content: const Text('An account with this user ID already exists. Would you like to log in instead?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: const Text('Login'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
        return;
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      String? fileUrl;

      if (_selectedUserType == 'Student') {
        fileUrl = await _uploadFile(userCredential.user!.uid);
        if (fileUrl == null) {
          print('File upload failed or no file was uploaded.');
          return; // Optionally return if file upload fails
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'birthday': _birthdayController.text,
        'userType': _selectedUserType,
        'email': _emailController.text,
        'age': _ageController.text,
        'phone': _phoneController.text,
        'userID': _userIDController.text,
        'profileIconIndex': 0,
        'wallet': 0,
        'userStatus': 'On Approval',
        'lastLogin': 'N/A',
        if (fileUrl != null) 'certificateUrl': fileUrl,
        'registerTime': FieldValue.serverTimestamp(), // Add register timestamp
        'seen': false,
      });

      // Show success dialog after registration
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Registration Successful!'),
            content: const Text('You have successfully registered. Would you like to log in now or return to the registration form?'),
            actions: [
              TextButton(
                onPressed: () {
                  // Navigate to login page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  _firstNameController.clear();
                  _lastNameController.clear();
                  _formKey.currentState?.reset();
                  _emailController.clear();
                  _passwordController.clear();
                  _confirmPasswordController.clear();
                  _birthdayController.clear();
                  _ageController.clear();
                  _phoneController.clear();
                  _userIDController.clear();
                  setState(() {
                    _selectedUserType = null; // Clear selected user type
                  });
                  Navigator.pop(context); // Close the dialog
                },
                child: const Text('Register Again'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      if (_phoneController.text.isNotEmpty &&
          !_phoneController.text.startsWith('09')) {
        // If the input does not start with '09', replace it with '09'
        _phoneController.text = '09' + _phoneController.text.replaceFirst(RegExp(r'^0+'), '');
        _phoneController.selection = TextSelection.fromPosition(TextPosition(offset: _phoneController.text.length)); // Move the cursor to the end
      }
    });
  }
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.png', // Replace with your background image
              fit: BoxFit.cover, // Adjust the image to cover the entire screen
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Image.asset('assets/images/FitTrack_Icon.png', height: 200),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'Enter first name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Enter last name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context),
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _birthdayController,
                                decoration: const InputDecoration(
                                  labelText: 'Birthday',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your birthday';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your age';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _userIDController,
                      decoration: const InputDecoration(
                        labelText: 'Faculty or Student ID',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedUserType,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedUserType = newValue;
                        });
                      },
                      items: ['Student', 'Faculty']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'User Type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a user type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    if (_selectedUserType == 'Student')
                      Column(
                        children: [
                          TextButton(
                            onPressed: _pickFile,
                            child: const Text('Upload Certificate of Enrollment'),
                          ),
                          if (_selectedFile != null)
                            Text(
                              'Selected file: ${_selectedFile!.name} ${_selectedFile?.size}',
                              style: const TextStyle(color: Colors.green),
                            ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(), // Loading indicator
                      )
                    else
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() == true) {
                          register();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Set background color to green
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(color: Colors.white), // Set text color to white
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Log in',
                            style: const TextStyle(color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => LoginPage()),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40, // Position the button at the top
            left: 20, // Align to the left
            child: FloatingActionButton(
              mini: true, // Smaller back button
              backgroundColor: Colors.green,
              onPressed: () {
                Navigator.pop(context); // Navigate back to the previous screen
              },
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
