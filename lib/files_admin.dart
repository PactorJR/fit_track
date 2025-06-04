import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Storage Admin',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FilesAdminPage(),
    );
  }
}

class FilesAdminPage extends StatefulWidget {
  @override
  _FilesAdminPageState createState() => _FilesAdminPageState();
}

class _FilesAdminPageState extends State<FilesAdminPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<String> _filesAndFolders = [];
  List<String> userIdToFolder = [];
  String _currentPath = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _listFilesAndPaths();
  }

  bool _isLoading = true;
  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _listFilesAndPaths(),
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

  Future<String> getUserName(String userId) async {
    try {

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;


        String firstName = data['firstName'] ?? 'Unknown';
        String lastName = data['lastName'] ?? 'User';
        return '$firstName $lastName';
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      print("Error fetching user details for userId $userId: $e");
      return 'Unknown User';
    }
  }


  Future<void> _listFilesAndPaths([String path = '']) async {
    setState(() {
      _loading = true;
      _currentPath = path;
    });

    try {
      final ListResult result = await _storage.ref(_currentPath).listAll();

      List<String> folderDetails = [];
      List<String> fileDetails = [];
      List<String> folderUserId = [];


      for (var folderRef in result.prefixes) {
        if (_currentPath.startsWith('enrollment_certificates')) {
          print('Processing folder path: ${folderRef.fullPath}');
          String userId = folderRef.name;
          String userName = await getUserName(userId);
          folderDetails.add('$userName/');
          folderUserId.add('$userId/');
        } else {

          if (folderRef.name == 'enrollment_certificates') {
            folderDetails.add(folderRef.fullPath + '/');
          }
        }
      }


      for (var fileRef in result.items) {
        print('Processing file path: ${fileRef.fullPath}');

        if (_currentPath.startsWith('enrollment_certificates/')) {
          List<String> parts = _currentPath.split('/');
          if (parts.length < 2) {
            print('Skipping file path (unexpected structure): ${fileRef.fullPath}');
            continue;
          }

          String userId = parts[1];
          String userName = await getUserName(userId);
          fileDetails.add('$userName - ${fileRef.name}');
        } else {
          fileDetails.add(fileRef.name);
        }
      }

      setState(() {
        _filesAndFolders = folderDetails + fileDetails;
        userIdToFolder = folderUserId;
        _loading = false;
      });
    } catch (e) {
      print("Error listing files and paths: $e");
      setState(() {
        _loading = false;
      });
    }
  }


  void _goToParentFolder() {
    _listFilesAndPaths('');
  }


  @override

  Future<void> _downloadFile(String fileName) async {
    try {
      await _requestPermissions();

      String fitTrackPath = '/storage/emulated/0/FitTrack';
      String certificatesPath = '$fitTrackPath/Files/Certificates';

      final fitTrackFolder = Directory(fitTrackPath);
      if (!await fitTrackFolder.exists()) {
        await fitTrackFolder.create(recursive: true);
      }

      final certificatesFolder = Directory(certificatesPath);
      if (!await certificatesFolder.exists()) {
        await certificatesFolder.create(recursive: true);
      }

      String filePath = '$certificatesPath/$fileName';
      final refPath = '$_currentPath/$fileName';
      final ref = _storage.ref(refPath);

      try {
        final url = await ref.getDownloadURL();
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          print('File downloaded and saved to: $filePath');
        } else {
          throw Exception('Failed to download file. HTTP Status: ${response.statusCode}');
        }
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          throw Exception('File does not exist at: $refPath');
        } else {
          rethrow;
        }
      }
    } catch (e) {
      print("Error downloading file: $e");
    }
  }

  Future<void> _requestPermissions() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      print("Storage permission granted");
    } else {
      print("Storage permission denied");
      throw Exception('Storage permission denied');
    }
  }



  Future<String> getFilePath(String fileName) async {
    final directory = await getExternalStorageDirectory();
    final path = directory?.path ?? '/storage/emulated/0';
    return '$path/FitTrack/Files/Certificates/$fileName';
  }

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
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder,
                    size: 24,
                    color: isDarkMode ? Colors.white : Colors.green,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Files Management',
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

          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 600),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.black38 : Colors.white,
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: Colors.green,
                                  width: 2.0,
                                ),
                              ),
                              child: Stack(
                                children: [

                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [

                                        Text(
                                          'Admin Files',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : Colors.black,
                                          ),
                                        ),


                                        if (_currentPath.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              _currentPath,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),

                                        SizedBox(height: 0),


                                        Center(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: _filesAndFolders.length,
                                            itemBuilder: (context, index) {
                                              final pathOrFile = _filesAndFolders[index];
                                              final isFolder = pathOrFile.endsWith('/');
                                              final userIdFolder = userIdToFolder.isNotEmpty ? userIdToFolder[index] : '';

                                              return ListTile(
                                                leading: Icon(
                                                  isFolder ? Icons.folder : Icons.file_copy,
                                                  color: isDarkMode ? Colors.white : Colors.black,
                                                ),
                                                title: Text(
                                                  pathOrFile,
                                                  style: TextStyle(
                                                    color: isDarkMode ? Colors.white : Colors.black,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                trailing: isFolder
                                                    ? Icon(Icons.arrow_forward, color: isDarkMode ? Colors.white : Colors.black)
                                                    : IconButton(
                                                  icon: Icon(Icons.download, color: isDarkMode ? Colors.white : Colors.black),
                                                  tooltip: 'Download',
                                                  onPressed: () async {
                                                    final actualFileName = pathOrFile.split(' - ').last;

                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Downloading $actualFileName...')),
                                                    );

                                                    await _downloadFile(actualFileName);

                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Downloaded $actualFileName successfully!')),
                                                    );
                                                  },
                                                ),
                                                onTap: isFolder
                                                    ? () {
                                                  String actualPath;
                                                  if (pathOrFile.startsWith('enrollment_certificates/')) {

                                                    String userId = pathOrFile.replaceFirst('enrollment_certificates/', '').replaceAll('/', '');
                                                    actualPath = 'enrollment_certificates/$userId';
                                                    print("enrollment certificates condition");
                                                  } else if (_currentPath == 'enrollment_certificates/' || _currentPath == 'enrollment_certificates') {

                                                    String userId = userIdFolder.replaceAll('/', '');
                                                    actualPath = 'enrollment_certificates/$userId';
                                                    print("root enrollment certificates condition");
                                                  } else {

                                                    actualPath = pathOrFile;
                                                    print("regular folder navigation");
                                                  }

                                                  _listFilesAndPaths(actualPath);
                                                }
                                                    : null,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),


                                  if (_currentPath.isNotEmpty)
                                    Positioned(
                                      top: 8.0,
                                      left: 8.0,
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
                                        onPressed: _goToParentFolder,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
}