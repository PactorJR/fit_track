import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'register.dart';
import 'guest.dart';
import 'home_page.dart';
import 'home_page_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';  // Add this import
import 'theme_provider.dart';  // Import your ThemeProvider file
import 'package:flutter/services.dart'; // Add this import


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,   // Normal portrait
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyAppMain());
}

class MyAppMain extends StatelessWidget {
  const MyAppMain({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (context) => ThemeProvider(),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            theme: Provider.of<ThemeProvider>(context).themeData,
            home: OpeningPage(),
            routes: {
              '/login': (context) => LoginPage(),
              '/register': (context) => RegisterPage(),
              '/guest': (context) => GuestPage(),
            },
          );
        },
      ),
    );
  }
}



class OpeningPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<OpeningPage> {
  bool rememberMe = false; // Track whether the user selects "Remember Me"
  final FlutterSecureStorage storage = FlutterSecureStorage();
  bool _isLoggedOut = false;  // Flag to track logout status

  @override
  void initState() {
    super.initState();
    _checkRememberMe();
    _showLoggedInSnackbar();
  }

  Future<void> _showLoggedInSnackbar() async {
    // Only show the snackbar if the user is not logged out
    if (_isLoggedOut) {
      return;  // Skip showing snackbar if logged out
    }

    String? rememberMeValue = await storage.read(key: 'isRemembered');
    if (rememberMeValue == 'false') {
      // Show Snackbar with session expired message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Your login session has expired!"),
          behavior: SnackBarBehavior.floating, // Floating snackbar
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _checkRememberMe() async {
    String? value = await storage.read(key: 'isRemembered');

    if (value == 'true') {
      // Proceed to check if the user is logged in or auto-login logic
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is already logged in, navigate to the appropriate home page
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String userType = userDoc['userType'];

        if (userType == 'Admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyAdminHomePage(title: 'FitTrack Home')),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage(title: 'Home')),
          );
        }
      }
    } else {
      // If rememberMe is false, sign the user out and show the snackbar
      await FirebaseAuth.instance.signOut();
      setState(() {
        _isLoggedOut = true;  // Set the flag to true after logout
      });
      _showLoggedInSnackbar();  // Correct method call here
    }
  }

  final PageController _controller = PageController();
  int _currentPage = 0;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for the slides
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              SlideWidget(
                image: 'assets/images/op_img.png',
                title: 'FitTrack CCAT: Where Campus Life Meets Workout Vibes!',
              ),
              SlideWidget(
                image: 'assets/images/op_img.png',
                title: 'FitTrack CCAT: Your Gym Near You!',
              ),
              SlideWidget(
                image: 'assets/images/op_img.png',
                title: 'FitTrack CCAT: Your Campus Workout Sidekick',
              ),
            ],
          ),
          // Top-left positioned op_img logo
          Positioned(
            top: 40,
            left: 20,
            child: Image.asset(
              'assets/images/FitTrack_Icon.png',
              width: 170,
              height: 170,
            ),
          ),
          // Add an image in the center
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: 3,
                effect: ExpandingDotsEffect(
                  dotWidth: 10.0,
                  dotHeight: 10.0,
                  activeDotColor: Colors.green,
                  dotColor: Colors.grey,
                ),
              ),
            ),
          ),
          // Buttons for login, register, guest login
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Login as Member Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login'); // Navigate to login
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text('Login as Member'),
                      ),
                    ),
                    SizedBox(width: 10), // Space between buttons
                    // Register Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register'); // Navigate to register
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text('Register'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20), // Space between row and guest login
                // Full-width Login as Guest Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/guest'); // Navigate to guest
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Login as Guest',
                      style: TextStyle(color: Colors.green),
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
}

class SlideWidget extends StatelessWidget {
  final String image;
  final String title;

  SlideWidget({required this.image, required this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          image,
          fit: BoxFit.cover,
        ),
        Container(
          color: Colors.black.withOpacity(0.5),
        ),
        Center(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32, // Increased font size
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.5), // Optional text shadow
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
