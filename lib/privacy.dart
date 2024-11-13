import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy'),
      ),
      body: Center(
        child: Text(
          'This is the Privacy Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
