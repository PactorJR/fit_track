import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'dart:async';
import 'dart:io';
import 'scan_guest.dart';
import 'package:flutter/services.dart';

class GuestPage extends StatefulWidget {
  @override
  _GuestPageState createState() => _GuestPageState();
}

class _GuestPageState extends State<GuestPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? userType;
  String? selectedDepartment;
  String successMessage = "";
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> submitData() async {
    try {

      String firstName = firstNameController.text.trim();
      String lastName = lastNameController.text.trim();
      String phoneNumber = phoneController.text.trim();
      String age = ageController.text.trim();
      String? selectedUserType = userType;


      Map<String, dynamic> guestData = {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': int.tryParse(phoneNumber) ?? 0,
        'age': int.tryParse(age) ?? 0,
        'userType': selectedUserType ?? '',
        'amountPaid': 0,
        'timeStamp': DateTime.now(),
      };


      await FirebaseFirestore.instance.collection('guests').add(guestData);


      firstNameController.clear();
      lastNameController.clear();
      ageController.clear();
      phoneController.clear();


      setState(() {
        userType = null;
        selectedDepartment = null;
        successMessage = "";
      });


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScanGuest(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneController.text.trim(),
            age: ageController.text.trim(),
            userType: userType ?? '',
          ),
        ),
      );
    } catch (e) {

      setState(() {
        successMessage = "Error submitting data, please try again.";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
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
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        Image.asset(
                          'assets/images/FitTrack_Icon.png',
                          height: 150,
                        ),
                        const SizedBox(height: 30),

                        TextField(
                          controller: firstNameController,
                          decoration: InputDecoration(labelText: 'First Name'),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: lastNameController,
                          decoration: InputDecoration(labelText: 'Last Name'),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: ageController,
                          decoration: InputDecoration(labelText: 'Age'),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: phoneController,
                          decoration: InputDecoration(labelText: 'Phone Number'),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: userType,
                          hint: Text('Select User Type', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                          items: ['Student', 'Faculty']
                              .map((type) =>
                              DropdownMenuItem(value: type, child: Text(type,  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black))))
                              .toList(),
                          onChanged: (value) =>
                              setState(() {
                                userType = value;
                                selectedDepartment = null;
                              }),
                        ),
                        SizedBox(height: 10),
                        if (userType != null)
                          DropdownButtonFormField<String>(
                            value: selectedDepartment,
                            hint: Text('Select Department',  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                            items: [
                              'Department of Art and Sciences',
                              'Department of Computer Studies',
                              'Department of Industrial Technology',
                              'Department of Engineering',
                              'Department of Management Studies',
                              'Department of Teacher Education',
                            ]
                                .map((dept) =>
                                DropdownMenuItem(
                                    value: dept, child: Text(dept,  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black))))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => selectedDepartment = value),
                          ),
                        SizedBox(height: 20),
                        ElevatedButton(onPressed: submitData, child: Text(
                            'Submit')),
                        SizedBox(height: 10),
                        if (successMessage.isNotEmpty)
                          Text(
                            successMessage,
                            style: TextStyle(
                              color: successMessage.contains("Error")
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }
}
