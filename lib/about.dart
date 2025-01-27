import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              isDarkMode ? 'assets/images/dark_bg.png' : 'assets/images/bg.png',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.green.shade800,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 350, // Fixed width
                    height: 650, // Fixed height
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.white, size: 30),
                            const SizedBox(width: 10),
                            Text(
                              'ABOUT FITTRACK',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              'FitTrack, the all-in-one mobile fitness tracking and membership application designed to empower you on your wellness journey. Whether you\'re a fitness newbie or a seasoned athlete, FitTrack seamlessly integrates cutting-edge technology with user-friendly features to help you achieve your goals and stay motivated.\n\n'
                                  'With FitTrack, you can effortlessly monitor your workouts, track your progress, and access personalized fitness plans tailored to your unique needs. Plus, with our diverse membership options, you\'ll gain access to exclusive content, expert advice, and a supportive community of like-minded fitness enthusiasts.\n\n'
                                  'FitTrack offers unparalleled Profile Freedom, allowing you to manage your BMI and privacy settings with ease, giving you control over how your data is shared and used. Keep track of your financial activity with our comprehensive History of Transactions feature, ensuring transparency and easy access to your past transactions.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.justify,
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
    );
  }
}
