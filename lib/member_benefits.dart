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
  int _currentPage = 0;

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
            child: Center(

            ),
          ),


          Positioned.fill(
            top: 0,
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


          Positioned(
            bottom: 10,
            right: 10,
            child: Image.asset(
              'assets/images/FitTrack_Icon.png',
              width: 80,
              height: 80,
            ),
          ),


          Positioned(
            bottom: 10,
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
    );
  }
}

class SlideWidget extends StatelessWidget {
  final String image;
  final String title;
  final bool isDarkMode;

  const SlideWidget({required this.image, required this.title, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [

        Image.asset(
          image,
          fit: BoxFit.cover,
        ),


        Positioned(
          bottom: 10,
          left: 20,
          right: 20,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: Colors.lightGreen,
            ),
          ),
        ),
      ],
    );
  }
}
