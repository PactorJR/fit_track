import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart'; // Assuming you want to use the theme provider
import 'theme_provider.dart';
import 'dart:io'; // For file operations
import 'package:http/http.dart' as http; // To download files
import 'package:path_provider/path_provider.dart'; // To get app directory
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_app_check/firebase_app_check.dart';


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
  String _currentPath = ''; // To keep track of the current folder path
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _listFilesAndPaths();
  }

  Future<void> _downloadFile(String fileName) async {
    try {
      // Request permissions to manage external storage
      await requestStoragePermission();

      // Define the base path for FitTrack storage
      const fitTrackPath = '/storage/emulated/0/FitTrack';
      String specificPath;

      // Determine the specific folder based on the current path
      if (_currentPath.contains('enrollment_certificates')) {
        specificPath = '$fitTrackPath/Files/Certificates';
      } else if (_currentPath.contains('userProfiles')) {
        specificPath = '$fitTrackPath/Files/userProfiles';
      } else {
        throw Exception('Unknown path: $_currentPath');
      }

      // Create the FitTrack base directory if it doesn't exist
      final fitTrackFolder = Directory(fitTrackPath);
      if (!await fitTrackFolder.exists()) {
        await fitTrackFolder.create(recursive: true);
      }

      // Create the specific directory if it doesn't exist
      final specificFolder = Directory(specificPath);
      if (!await specificFolder.exists()) {
        await specificFolder.create(recursive: true);
      }

      // Define the file path inside the specific folder
      final filePath = '$specificPath/$fileName';

      // Create a reference to the file in Firebase Storage
      final ref = _storage.ref('$_currentPath/$fileName');

      // Generate a download URL for the file
      final url = await ref.getDownloadURL();
      print("Download URL for $fileName: $url");

      // Download the file and save it locally
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print('File downloaded and saved to: $filePath');
      } else {
        throw Exception('Failed to download file. HTTP Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error downloading file: $e");
    }
  }

  Future<void> requestStoragePermission() async {
    if (!await Permission.storage.request().isGranted) {
      throw Exception('Storage permission denied');
    }
  }

  Future<String> getFilePath(String fileName) async {
    final directory = await getExternalStorageDirectory();
    final path = directory?.path ?? '/storage/emulated/0'; // Fallback
    return '$path/FitTrack/Files/Certificates/$fileName';
  }

  // List files and folders for a given path
  Future<void> _listFilesAndPaths([String path = '']) async {
    setState(() {
      _loading = true;
      _currentPath = path; // Set the path, defaults to root if empty
    });

    try {
      final ListResult result = await _storage.ref(_currentPath).listAll();
      List<String> folders = result.prefixes.map((ref) => ref.fullPath + '/').toList(); // Add '/' to folders
      List<String> files = result.items.map((ref) => ref.name).toList(); // File names only

      setState(() {
        _filesAndFolders = folders + files; // Combine folders and files
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
    if (_currentPath.isNotEmpty) {
      final parentPath = _currentPath.contains('/')
          ? _currentPath.substring(0, _currentPath.lastIndexOf('/'))
          : '';
      _listFilesAndPaths(parentPath);
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

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
                      : 'assets/images/bg.png',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Header content positioned at the top
          Positioned(
            top: 60, // Adjust the top value as needed
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

          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600), // Limit the maximum width
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Minimize space taken by the column
                    children: [
                      // If not in root, show a back button to navigate to the parent folder
                      if (_currentPath.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
                          onPressed: _goToParentFolder,
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black38 : Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Adjust space usage
                            children: [
                              // Title Section
                              Text(
                                'Admin Files', // Title for the section
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.white,
                                ),
                              ),

                              // Path Indicator
                              if (_currentPath.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _currentPath, // Show current path
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70, // Slightly lighter text color for contrast
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              SizedBox(height: 0),

                              // ListView displaying files and folders
                            Center(
                              child: ListView.builder(
                                shrinkWrap: true, // Prevent ListView from expanding unnecessarily
                                itemCount: _filesAndFolders.length, // Total number of files/folders
                                itemBuilder: (context, index) {
                                  final pathOrFile = _filesAndFolders[index]; // Current file/folder
                                  final isFolder = pathOrFile.endsWith('/'); // Check if it's a folder

                                  return ListTile(
                                    leading: Icon(
                                      isFolder ? Icons.folder : Icons.file_copy, // Show folder or file icon
                                      color: isDarkMode ? Colors.white : Colors.black, // Adjust icon color
                                    ),
                                    title: Text(
                                      pathOrFile, // Display file or folder name
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black, // Adjust text color
                                        fontWeight: FontWeight.w500, // Slightly bold text for readability
                                      ),
                                    ),
                                    trailing: isFolder
                                        ? Icon(Icons.arrow_forward, color: isDarkMode ? Colors.white : Colors.black) // Arrow icon for folders
                                        : IconButton(
                                      icon: Icon(Icons.download, color: isDarkMode ? Colors.white : Colors.black),
                                      tooltip: 'Download',
                                      onPressed: () async {
                                        // Show a loading indicator in the snackbar during the download
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Downloading $pathOrFile...')),
                                        );

                                        // Wait for the file to be downloaded and then show the Snackbar with file path
                                        await _downloadFile(pathOrFile);

                                        // After download, show the completion snackbar
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Downloaded $pathOrFile successfully!')),
                                        );
                                      },
                                    ), // Download button for files
                                    onTap: isFolder
                                        ? () {
                                      _listFilesAndPaths(pathOrFile); // Navigate into folder
                                    }
                                        : null, // Disable tap action for files
                                  );
                                },
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

          // Back button
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