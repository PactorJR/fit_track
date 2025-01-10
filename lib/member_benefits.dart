import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'theme_provider.dart';

class MemberBenefitsPage extends StatefulWidget {
  @override
  _MemberBenefitsPageState createState() => _MemberBenefitsPageState();
}

class _MemberBenefitsPageState extends State<MemberBenefitsPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;  // Track the current page index

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          // Background container
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isDarkMode
                      ? 'assets/images/dark_bg.png' // Dark mode background
                      : 'assets/images/bg.png',    // Light mode background
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              // You can add more content here if needed
            ),
          ),

          // PageView for the slides
          Positioned.fill(
            top: 0, // Adjust the top position to place it below the title
            child: PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                SlideWidget(
                  image: 'assets/images/Slide1.png',
                  title: 'Access detailed exercise tutorials for correct form and technique.',
                  isDarkMode: isDarkMode,
                ),
                SlideWidget(
                  image: 'assets/images/Slide2.png',
                  title: 'Stay informed about gym protocols and health reminders.',
                  isDarkMode: isDarkMode,
                ),
                SlideWidget(
                  image: 'assets/images/Slide3.png',
                  title: 'Track past activities and transactions with ease.',
                  isDarkMode: isDarkMode,
                ),
                SlideWidget(
                  image: 'assets/images/Slide4.png',
                  title: 'Quickly access exercise tutorials linked to specific QR codes.',
                  isDarkMode: isDarkMode,
                ),
                SlideWidget(
                  image: 'assets/images/Slide5.png',
                  title: 'Easily manage gym credits or payments through QR codes.',
                  isDarkMode: isDarkMode,
                ),
                SlideWidget(
                  image: 'assets/images/Slide6.png',
                  title: 'Personalize your experience and keep track of your details.',
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),

          // Top-left positioned op_img logo
          Positioned(
            bottom: 10,
            right: 10,
            child: Image.asset(
              'assets/images/FitTrack_Icon.png',
              width: 80,
              height: 80,
            ),
          ),

          // SmoothPageIndicator at the bottom center
          Positioned(
            bottom: 10,  // Adjust this value to move the indicator up or down
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: 6,
                effect: ExpandingDotsEffect(
                  dotWidth: 10.0,
                  dotHeight: 10.0,
                  activeDotColor: Colors.green,
                  dotColor: Colors.grey,
                ),
              ),
            ),
          ),

          // Positioned floating action button
          Positioned(
            top: 60, // Adjust this value to move the button down
            left: 16, // Horizontal position
            child: FloatingActionButton(
              mini: true, // Smaller back button
              backgroundColor: isDarkMode ? Colors.grey : Colors.green,
              onPressed: () {
                Navigator.of(context).pop(); // Navigate back to the previous screen
              },
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// SlideWidget for each page in PageView
class SlideWidget extends StatelessWidget {
  final String image;
  final String title;
  final bool isDarkMode;

  const SlideWidget({required this.image, required this.title, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,  // Make the image fill the screen
      children: [
        // Background image filling the page
        Image.asset(
          image,
          fit: BoxFit.cover, // The image will cover the whole screen
        ),

        // Positioned text title on top of the image (bottom)
        Positioned(
          bottom: 10,  // Adjust the position of the text
          left: 20,
          right: 20,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic, // Makes the font italic
              color: Colors.green, // White text color for better contrast
            ),
          ),
        ),
      ],
    );
  }
}
