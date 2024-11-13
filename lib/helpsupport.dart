import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
      ),
      body: Center(
        child: Text(
          'This is the Help & Support Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}