import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  @override
  _HelpSupportPageState createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  int? _expandedIndex;


  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.facebook.com/profile.php?id=61572143510811');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      print("Error launching URL: $e");
    }
  }


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
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.green.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  height: 650,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help, color: Colors.white, size: 30),
                          const SizedBox(width: 10),
                          Text(
                            'HELP CENTER',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                      Expanded(
                        child: _buildQuestionsList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _launchURL,
                backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.green,
                child: Icon(Icons.chat, color: Colors.white),
                heroTag: "help_button",
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


  Widget _buildQuestionsList() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    final List<Map<String, String>> questions = [
      {'question': 'When did the gym open?', 'answer': 'Around late 2022'},
      {
        'question': 'What gym equipment does the gym offer?',
        'answer': 'Multifunctional Exercise Machine, Barbell Bench, Dumbbell Bench, Pull Up Bar, Bare Steel Equipment.'
      },
      {
        'question': 'How many customers does the gym accept each day?',
        'answer': '3 to 5 users depending on the day.'
      },
      {
        'question': 'What is the typical workflow of the gym from when a customer arrives to when they leave?',
        'answer': 'Sign up on hostel, Scan QR, Pay, Get Key, Use Gym, CAYGO, Close Windows, Give Key Back.'
      },
      {
        'question': 'How do you handle situations when a customer loses or finds a valuable item belonging to another customer?',
        'answer': 'They will be contacted through the personal information of the users they have personally put in the database.'
      },
    ];

    return ListView.builder(
      itemCount: questions.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              if (_expandedIndex == index) {
                _expandedIndex = null;
              } else {
                _expandedIndex = index;
              }
            });
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 5),
            color: isDarkMode ? Colors.grey.shade700 : Colors.green.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    questions[index]['question']!,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  trailing: Icon(
                    _expandedIndex == index
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.white,
                  ),
                ),
                AnimatedSize(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _expandedIndex == index
                      ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      questions[index]['answer']!,
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                      : SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
