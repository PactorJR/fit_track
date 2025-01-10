import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text('Help Center'),
          bottom: TabBar(
            indicatorColor: Colors.pinkAccent,
            tabs: [
              Tab(text: 'QUESTIONS'),
              Tab(text: 'TOPICS'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search for questions',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildQuestionsList(),
                  Center(child: Text('Topics Tab Content')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    final List<Map<String, String>> questions = [
      {'question': 'When did the gym open?', 'answer': 'Around late 2022'},
      {'question': 'What gym equipment does the gym offer?', 'answer': 'Multifunctional Exercise Machine, Barbell Bench, Dumbbell Bench, Pull Up Bar, Bare Steel Equipment.'},
      {'question': 'How many customers does the gym accept each day?', 'answer': '3 to 5 users depending on the day.'},
      {'question': 'What is the typical workflow of the gym from when a customer arrives to when they leave?', 'answer': 'Sign up on hostel, Scan QR, Pay, Get Key, Use Gym, CAYGO, Close Windows, Give Key Back.'},
      {'question': 'How do you handle situations when a customer loses or finds a valuable item belonging to another customer?', 'answer': 'They will be contacted through the personal information of the users they have personally put in the database.'},
      // Add more questions as needed
    ];

    return ListView.builder(
      itemCount: questions.length,
      itemBuilder: (context, index) {
        return ExpansionTile(
          title: Text(
            questions[index]['question']!,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(questions[index]['answer']!),
            ),
          ],
        );
      },
    );
  }
}
