import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;


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

  // Request permissions before accessing external storage
  Future<void> requestPermissions() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      // Proceed with downloading the file
    } else {
      // Handle permission denial
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permission denied')));
    }
  }

  Future<void> _downloadEquipmentData() async {
    try {
      print(selectedEquipId);
      if (selectedEquipId?.isNotEmpty ?? false) {
        // Retrieve the equipment title from your data model based on the selected ID
        final equipmentTitle = await _getEquipmentTitleById(selectedEquipId);
        print(equipmentTitle);
        // Example: Prepare data for download
        final equipmentData = "Equipment ID: $selectedEquipId\nName: $equipmentTitle";

        // Generate the QR code from the equipment data
        final qrCode = await _generateQRCode();

        // Custom directory path for internal storage
        String fitTrackPath = '/storage/emulated/0/FitTrack';

        // Create the FitTrack directory if it doesn't exist
        final fitTrackFolder = Directory(fitTrackPath);
        if (!await fitTrackFolder.exists()) {
          await fitTrackFolder.create(recursive: true);
        }

        // Create the "QRCodes" subdirectory inside FitTrack
        final qrCodesFolder = Directory('$fitTrackPath/QRCodes');
        if (!await qrCodesFolder.exists()) {
          await qrCodesFolder.create(recursive: true);
        }

        // Define the file path inside the "QRCodes" folder, including equipment title in the file name
        String filePath = '$fitTrackPath/QRCodes/${equipmentTitle}_QR.png';
        final file = File(filePath);

        // Write the QR code image to the file
        await file.writeAsBytes(qrCode);

        // Inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code saved: $filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an equipment item')),
        );
      }
    } catch (e) {
      // Handle errors
      print('Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download file')),
      );
    }
  }

  Future<String> _getEquipmentTitleById(String? equipId) async {
    try {
      // Simulating a database fetch using Firestore
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
      // Ensure selectedEquipId is valid
      if (selectedEquipId?.isNotEmpty ?? false) {
        // Fetch the equipLink field from the selected equipment document
        final documentSnapshot = await FirebaseFirestore.instance
            .collection('equipments')
            .doc(selectedEquipId)
            .get();

        if (!documentSnapshot.exists) {
          throw Exception('Selected equipment not found in the database');
        }

        // Extract the equipLink field
        final equipLink = documentSnapshot.data()?['equipLink'] as String?;
        if (equipLink == null || equipLink.isEmpty) {
          throw Exception('equipLink field is missing or empty in the selected equipment document');
        }

        // Create the QR code widget using equipLink as the data
        final qrValidationResult = QrCode.fromData(
          data: equipLink,
          errorCorrectLevel: QrErrorCorrectLevel.L,
        );

        // Create an image from the QR code
        final qrPainter = QrPainter.withQr(
          qr: qrValidationResult,
          color: Colors.black,
          gapless: true,
        );

        // Convert to ByteData
        final picData = await qrPainter.toImageData(2048); // Use desired size (2048px)
        if (picData == null) {
          throw Exception('Failed to generate QR code image data');
        }

        // Convert ByteData to Uint8List and add a white background
        final image = await qrPainter.toImage(2048); // Convert to Image
        final width = image.width;
        final height = image.height;

        // Create a white background canvas with the same size as the QR code
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(
          recorder,
          Rect.fromPoints(Offset(0, 0), Offset(width.toDouble(), height.toDouble())),
        );

        // Draw the white background
        canvas.drawColor(Colors.white, BlendMode.srcOver);

        // Paint the QR code onto the canvas
        canvas.drawImage(image, Offset(0, 0), Paint());

        // Finish the recording and convert it to a byte array
        final picture = recorder.endRecording();
        final img = await picture.toImage(width, height);
        final byteDataWithBg = await img.toByteData(format: ui.ImageByteFormat.png);

        // Return the byte data of the image with white background
        return byteDataWithBg!.buffer.asUint8List();
      } else {
        throw Exception('No equipment selected');
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
                  decoration: InputDecoration(labelText: 'Equipment Title'),
                ),
                SizedBox(height: 8.0),
                TextField(
                  controller: linkController,
                  decoration: InputDecoration(labelText: 'Equipment Link'),
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
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 24,
                    color: isDarkMode ? Colors.white : Colors.green,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Gym Equipment',
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: 'Search Equipment',
                            hintText: 'Enter equipment name',
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
                          color: isDarkMode
                              ? Colors.black38
                              : Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Equipment Information',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              SingleChildScrollView(
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
                                          child: Text('No equipment found.'));
                                    }

                                    var filteredDocs = snapshot.data!.docs.where((doc) {
                                      var title =
                                      (doc['equipTitle'] ?? '').toLowerCase();
                                      return title.contains(searchTerm);
                                    }).toList();

                                    if (filteredDocs.isEmpty) {
                                      return Center(
                                          child:
                                          Text('No matching equipment found.'));
                                    }

                                    return Table(
                                      border: TableBorder.all(),
                                      columnWidths: {
                                        0: FixedColumnWidth(150),
                                        1: FixedColumnWidth(200),
                                        2: FixedColumnWidth(100),
                                        3: FixedColumnWidth(150),
                                        4: FixedColumnWidth(80), // QR code column
                                      },
                                      children: [
                                        TableRow(
                                          children: [
                                            _headerCell('Equipment Title'),
                                            _headerCell('Equipment Link'),
                                            _headerCell('ID'),
                                            _headerCell('Timestamp'),
                                            _headerCell('QR Code'),
                                          ],
                                        ),
                                        ...filteredDocs.map((doc) {
                                          return TableRow(
                                            decoration: BoxDecoration(
                                              color: selectedEquipId == doc.id
                                                  ? Colors.white.withOpacity(0.8)
                                                  : Colors.transparent,
                                            ),
                                            children: [
                                              _tableCell(doc['equipTitle'] ?? '',
                                                      () => _selectEquipment(doc.id)),
                                              _tableCell(doc['equipLink'] ?? '',
                                                      () => _selectEquipment(doc.id)),
                                              _tableCell(doc.id,
                                                      () => _selectEquipment(doc.id)),
                                              _tableCell(
                                                doc['timeStamp'] != null
                                                    ? formatTimestamp(
                                                    doc['timeStamp'])
                                                    : '',
                                                    () => _selectEquipment(doc.id),
                                              ),
                                              TableCell(
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.all(8.0),
                                                  child: doc['equipLink'] != null
                                                      ? QrImageView(
                                                    data: doc['equipLink'],
                                                    version: QrVersions.auto,
                                                    size: 50.0,
                                                  )
                                                      : Text('No Link'),
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
                                children: [
                                  Expanded(
                                    child: _actionButton(
                                      onPressed: _createEquipment,
                                      icon: Icons.add,
                                      label: '',
                                      color: Colors.green,
                                    ),
                                  ),
                                  Expanded(
                                    child: _actionButton(
                                      onPressed: selectedEquipId?.isNotEmpty ?? false
                                          ? () => _editEquipment(context)
                                          : null,
                                      icon: Icons.edit,
                                      label: '',
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Expanded(
                                    child: _actionButton(
                                      onPressed: selectedEquipId?.isNotEmpty ?? false
                                          ? () =>
                                          _showDeleteConfirmationDialog(context)
                                          : null,
                                      icon: Icons.delete,
                                      label: '',
                                      color: Colors.red,
                                    ),
                                  ),
                                  Expanded(
                                    child: _actionButton(
                                      onPressed: selectedEquipId?.isNotEmpty ?? false
                                          ? _downloadEquipmentData
                                          : null,
                                      icon: Icons.download,
                                      label: '',
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              )
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
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8),
          Text(label, style: TextStyle(color: color)),
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
  final TextEditingController _timeStampController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Equipment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Equipment Title'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(labelText: 'Equipment Link'),
            ),
            SizedBox(height: 8.0),
            GestureDetector(
              onTap: () {
                _selectDateAndTime(context, _timeStampController);
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: _timeStampController,
                  decoration: InputDecoration(labelText: 'Timestamp'),
                ),
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

  void _saveEquipment() async {
    String title = _titleController.text.trim();
    String link = _linkController.text.trim();
    String timeStampString = _timeStampController.text.trim();
    DateTime? timeStampDateTime = DateTime.tryParse(timeStampString);
    Timestamp timeStamp = timeStampDateTime != null
        ? Timestamp.fromDate(timeStampDateTime)
        : Timestamp.now();

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