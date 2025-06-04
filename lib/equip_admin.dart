import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class EquipAdminPage extends StatefulWidget {
  final String? equipId;

  EquipAdminPage({this.equipId});

  @override
  _EquipAdminPageState createState() => _EquipAdminPageState();
}

class _EquipAdminPageState extends State<EquipAdminPage> {
  String? selectedEquipId;
  TextEditingController searchController = TextEditingController();
  String searchTerm = '';


  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  Future<void> requestPermissions() async {

    if (await Permission.manageExternalStorage.request().isGranted) {

      print("Storage permission granted");
    } else {

      print("Storage permission denied");
    }
  }

  Future<void> _downloadEquipmentData() async {
    try {
      print("Starting to download equipment data...");


      await requestPermissions();


      print("Selected Equip ID: $selectedEquipId");
      if (selectedEquipId?.isNotEmpty ?? false) {

        final equipmentTitle = await _getEquipmentTitleById(selectedEquipId);
        print("Equipment Title: $equipmentTitle");


        final equipmentData = "Equipment ID: $selectedEquipId\nName: $equipmentTitle";


        print("Generating QR code...");
        final qrCode = await _generateQRCode();
        print("QR code generated successfully.");


        String fitTrackPath = '/storage/emulated/0/FitTrack';
        print("FitTrack path: $fitTrackPath");


        final fitTrackFolder = Directory(fitTrackPath);
        if (!await fitTrackFolder.exists()) {
          print("FitTrack folder does not exist. Creating it...");
          await fitTrackFolder.create(recursive: true);
        } else {
          print("FitTrack folder already exists.");
        }


        final qrCodesFolder = Directory('$fitTrackPath/QRCodes');
        if (!await qrCodesFolder.exists()) {
          print("QRCodes folder does not exist. Creating it...");
          await qrCodesFolder.create(recursive: true);
        } else {
          print("QRCodes folder already exists.");
        }


        String filePath = '$fitTrackPath/QRCodes/${equipmentTitle}_QR.png';
        print("File path for QR code: $filePath");
        final file = File(filePath);


        print("Writing QR code to file...");
        await file.writeAsBytes(qrCode);
        print("QR code saved to $filePath");


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code saved: $filePath')),
        );
      } else {
        print("No equipment item selected.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an equipment item')),
        );
      }
    } catch (e) {

      print("Error downloading file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download file')),
      );
    }
  }



  Future<String> _getEquipmentTitleById(String? equipId) async {
    try {

      final doc = await FirebaseFirestore.instance.collection('equipments').doc(equipId).get();

      if (doc.exists) {
        return doc.data()?['equipTitle'] ?? 'Unknown Equipment';
      } else {
        return 'Equipment Not Found';
      }
    } catch (e) {
      print('Error fetching equipment title: $e');
      return 'Error Fetching Title';
    }
  }

  Future<Uint8List> _generateQRCode() async {
    try {

      if (selectedEquipId?.isNotEmpty ?? false) {

        final documentSnapshot = await FirebaseFirestore.instance
            .collection('equipments')
            .doc(selectedEquipId)
            .get();

        if (!documentSnapshot.exists) {
          throw Exception('Selected equipment not found in the database');
        }


        final equipLink = documentSnapshot.data()?['equipLink'] as String?;
        if (equipLink == null || equipLink.isEmpty) {
          throw Exception('equipLink field is missing or empty in the selected equipment document');
        }


        final qrValidationResult = QrCode.fromData(
          data: equipLink,
          errorCorrectLevel: QrErrorCorrectLevel.L,
        );


        final qrPainter = QrPainter.withQr(
          qr: qrValidationResult,
          color: Colors.black,
          gapless: true,
        );


        final picData = await qrPainter.toImageData(2048);
        if (picData == null) {
          throw Exception('Failed to generate QR code image data');
        }


        final image = await qrPainter.toImage(2048);
        final width = image.width;
        final height = image.height;


        final recorder = ui.PictureRecorder();
        final canvas = Canvas(
          recorder,
          Rect.fromPoints(Offset(0, 0), Offset(width.toDouble(), height.toDouble())),
        );


        canvas.drawColor(Colors.white, BlendMode.srcOver);


        canvas.drawImage(image, Offset(0, 0), Paint());


        final picture = recorder.endRecording();
        final img = await picture.toImage(width, height);
        final byteDataWithBg = await img.toByteData(format: ui.ImageByteFormat.png);


        return byteDataWithBg!.buffer.asUint8List();
      } else {
        throw Exception('No Workout selected');
      }
    } catch (e) {
      print('Error generating QR code: $e');
      rethrow;
    }
  }

  void _selectDateAndTime(BuildContext context,
      TextEditingController controller) async {
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

        String formattedDateTime = "${combinedDateTime
            .toLocal()
            .year
            .toString()
            .padLeft(4, '0')}-${(combinedDateTime.month).toString().padLeft(
            2, '0')}-${(combinedDateTime.day).toString().padLeft(
            2, '0')} ${combinedDateTime.hour.toString().padLeft(
            2, '0')}:${combinedDateTime.minute.toString().padLeft(2, '0')}";
        controller.text = formattedDateTime;
      }
    }
  }


  @override
  void initState() {
    super.initState();
    selectedEquipId = widget.equipId;
    if (selectedEquipId != null) {
      _selectEquipment(selectedEquipId!);
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _selectEquipment(String equipId) {
    setState(() {
      selectedEquipId = equipId;
    });
  }

  void _createEquipment() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateEquipmentDialog();
      },
    );
  }

  void _editEquipment(BuildContext context) async {
    DocumentSnapshot equipDoc = await FirebaseFirestore.instance
        .collection('equipments')
        .doc(selectedEquipId)
        .get();

    final titleController = TextEditingController(text: equipDoc['equipTitle']);
    final linkController = TextEditingController(text: equipDoc['equipLink']);
    final timeStampController = TextEditingController(
      text: equipDoc['timeStamp'] != null
          ? formatTimestamp(equipDoc['timeStamp'])
          : DateTime.now().toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Equipment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Workout Title'),
                ),
                SizedBox(height: 8.0),
                TextField(
                  controller: linkController,
                  decoration: InputDecoration(labelText: 'Workout Link'),
                ),
                SizedBox(height: 8.0),
                GestureDetector(
                  onTap: () {
                    _selectDateAndTime(context, timeStampController);
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: timeStampController,
                      decoration: InputDecoration(labelText: 'Timestamp'),
                    ),
                  ),
                ),
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
                DateTime? parsedTime = DateTime.tryParse(
                    timeStampController.text);
                Timestamp? newTimestamp = parsedTime != null ? Timestamp
                    .fromDate(parsedTime) : null;

                await FirebaseFirestore.instance
                    .collection('equipments')
                    .doc(selectedEquipId)
                    .update({
                  'equipTitle': titleController.text,
                  'equipLink': linkController.text,
                  'timeStamp': newTimestamp,
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

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
            left: MediaQuery.of(context).size.width / 2 - 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 24,
                  color: isDarkMode ? Colors.white : Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  'Workouts',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
    Padding(
    padding: const EdgeInsets.only(top: 100),
          child: Center(
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
                            labelText: 'Search Workout',
                            hintText: 'Enter Workout name',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.green,
                                width: 2.0,
                              ),
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
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black38 : Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: Colors.green,
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
                                'Workout Information',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20),

                              SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('equipments')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasError) {
                                        return Center(
                                            child: Text('Error: ${snapshot.error}'));
                                      }
                                      if (!snapshot.hasData ||
                                          snapshot.data!.docs.isEmpty) {
                                        return Center(
                                            child: Text('No Workout found.'));
                                      }

                                      var filteredDocs = snapshot.data!.docs.where((doc) {
                                        var title =
                                        (doc['equipTitle'] ?? '').toLowerCase();
                                        return title.contains(searchTerm);
                                      }).toList();

                                      if (filteredDocs.isEmpty) {
                                        return Center(
                                            child: Text('No matching Workout found.'));
                                      }

                                      return Table(
                                        border: TableBorder.all(),
                                        columnWidths: {
                                          0: FixedColumnWidth(120),
                                          1: FixedColumnWidth(200),
                                          2: FixedColumnWidth(100),
                                          3: FixedColumnWidth(80),
                                        },
                                        children: [
                                          TableRow(
                                            children: [
                                              _headerCell('Workout Title'),
                                              _headerCell('Workout Link'),
                                              _headerCell('Time Created'),
                                              _headerCell('QR Code'),
                                            ],
                                          ),
                                          ...filteredDocs.map((doc) {
                                            return TableRow(
                                              decoration: BoxDecoration(
                                                color: selectedEquipId == doc.id
                                                    ? Colors.green.withOpacity(0.2)
                                                    : Colors.transparent,
                                              ),
                                              children: [
                                                TableCell(
                                                  child: Center(
                                                    child: _tableCell(doc['equipTitle'] ?? '', () => _selectEquipment(doc.id)),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Center(
                                                    child: _tableCell(doc['equipLink'] ?? '', () => _selectEquipment(doc.id)),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Center(
                                                    child: _tableCell(
                                                      doc['timeStamp'] != null
                                                          ? formatTimestamp(doc['timeStamp'])
                                                          : '',
                                                          () => _selectEquipment(doc.id),
                                                    ),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(0.0),
                                                    child: doc['equipLink'] != null
                                                        ? Center(
                                                      child: QrImageView(
                                                        data: doc['equipLink'],
                                                        version: QrVersions.auto,
                                                        size: 50.0,
                                                      ),
                                                    )
                                                        : Center(child: Text('No Link')),
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
                              ),
                              SizedBox(height: 20),

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
      bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            unselectedLabelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(Icons.add, color: Colors.green),
                label: 'Create',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.edit,
                  color: (selectedEquipId?.isNotEmpty ?? false) ? Colors.blue : Colors.grey,
                ),
                label: 'Edit',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.delete,
                  color: (selectedEquipId?.isNotEmpty ?? false) ? Colors.red : Colors.grey,
                ),
                label: 'Delete',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.download,
                  color: (selectedEquipId?.isNotEmpty ?? false) ? Colors.orange : Colors.grey,
                ),
                label: 'Download',
              ),
            ],
            onTap: (int index) {
              switch (index) {
                case 0:
                  _createEquipment();
                  break;
                case 1:
                  if (selectedEquipId?.isNotEmpty ?? false) {
                    _editEquipment(context);
                  }
                  break;
                case 2:
                  if (selectedEquipId?.isNotEmpty ?? false) {
                    _showDeleteConfirmationDialog(context);
                  }
                  break;
                case 3:
                  if (selectedEquipId?.isNotEmpty ?? false) {
                    _downloadEquipmentData();
                  }
                  break;
              }
            },
          ),
    );
  }

  Widget _headerCell(String text) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _tableCell(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        child: Text(text),
      ),
    );
  }

  Widget _actionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {

    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;


    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;


    double buttonWidth = screenWidth < 360 ? screenWidth * 0.2 : screenWidth * 0.01;
    double buttonHeight = screenHeight < 360 ? 10 : 10;


    double fontSize = screenWidth < 360 ? 12 : 12;


    EdgeInsetsGeometry padding = screenWidth < 360
        ? EdgeInsets.symmetric(vertical: 0.2, horizontal: 0.4)
        : EdgeInsets.symmetric(vertical: 0.8, horizontal: 1);

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        padding: padding,
        backgroundColor: isDarkMode ? Colors.white : Colors.white,
        minimumSize: Size(buttonWidth, buttonHeight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(icon, color: color),
          SizedBox(height: 5),
          Text(label, style: TextStyle(color: color, fontSize: fontSize)),
        ],
      ),
    );
  }





  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this equipment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (selectedEquipId != null) {
                  FirebaseFirestore.instance
                      .collection('equipments')
                      .doc(selectedEquipId)
                      .delete();
                  setState(() {
                    selectedEquipId = null;
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class CreateEquipmentDialog extends StatefulWidget {
  @override
  _CreateEquipmentDialogState createState() => _CreateEquipmentDialogState();
}

class _CreateEquipmentDialogState extends State<CreateEquipmentDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Workout'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Workout Title'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(labelText: 'Workout Link'),
            ),
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
          onPressed: _saveEquipment,
          child: Text(
            'Create',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }

  void _saveEquipment() async {
    String title = _titleController.text.trim();
    String link = _linkController.text.trim();

    // Ensure the link starts with "https://"
    if (link.isNotEmpty && !link.startsWith('https://')) {
      link = 'https://' + link;
    }


  Timestamp timeStamp = Timestamp.now();

  if (title.isNotEmpty && link.isNotEmpty) {
  await FirebaseFirestore.instance.collection('equipments').add({
  'equipTitle': title,
  'equipLink': link,
  'timeStamp': timeStamp,
  });

  Navigator.of(context).pop();
  }
}
}