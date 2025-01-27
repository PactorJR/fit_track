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
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:flutter/services.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
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
            home: WillPopScope(
              onWillPop: () async {

                return false;
              },
              child: OpeningPage(),
            ),
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
  bool rememberMe = false;
  final FlutterSecureStorage storage = FlutterSecureStorage();
  bool _isLoggedOut = false;

  @override
  void initState() {
    super.initState();
    readSecureData();
    _checkRememberMe();
    _showLoggedInSnackbar();
  }

  Future<void> readSecureData() async {
    try {
      // Try reading the stored value (which may cause decryption issues)
      String? value = await storage.read(key: 'isRemembered');
      if (value != null) {
        print("Successfully retrieved secure data: $value");
      } else {
        print("No data found for the specified key.");
      }
    } catch (e) {
      print("Error reading secure storage: $e");

      // Check if the error is a BadPaddingException
      if (e.toString().contains("BadPaddingException")) {
        print("Decryption error detected: Bad padding. Possibly corrupted data.");
        await _resetSecureStorage(); // Reset the secure storage in case of corruption
      }
    }
  }


  Future<void> _showLoggedInSnackbar() async {
    if (_isLoggedOut) return;

    try {
      String? rememberMeValue = await storage.read(key: 'isRemembered');
      if (rememberMeValue == 'false') {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Your login session has expired!"),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print("Error showing snackbar: $e");
    }
  }

  Future<void> _checkRememberMe() async {
    try {
      String? value = await storage.read(key: 'isRemembered');

      if (value == 'true') {

        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {

          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          String userType = userDoc['userType'];

          if (userType == 'Admin') {
            _navigateToHomePage(MyAdminHomePage(title: 'FitTrack Home'));
          } else {
            _navigateToHomePage(MyHomePage(title: 'Home'));
          }
        }
      } else {

        await _logoutUser();
      }
    } catch (e) {
      print("Error checking Remember Me: $e");
      await _resetSecureStorage();
    }
  }

  Future<void> _logoutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      setState(() {
        _isLoggedOut = true;
      });
      await _showLoggedInSnackbar();
    } catch (e) {
      print("Error during logout: $e");
    }
  }

  Future<void> _resetSecureStorage() async {
    try {
      print("Resetting secure storage due to corruption or error.");
      await storage.deleteAll();
    } catch (e) {
      print("Error resetting secure storage: $e");
    }
  }

  void _navigateToHomePage(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {

        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [

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

            Positioned(
              top: 40,
              left: 20,
              child: Image.asset(
                'assets/images/FitTrack_Icon.png',
                width: 170,
                height: 170,
              ),
            ),

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

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginPage()),
                            );
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
                      SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterPage()),
                            );
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
                  SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GuestPage()),
                        );
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
    return WillPopScope(
      onWillPop: () async {

        return false;
      },
    child: Stack(
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
              fontSize: 32,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
    );
  }
}
