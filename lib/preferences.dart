import 'package:flutter/material.dart';

class PreferencesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preferences'),
      ),
      body: Center(
        child: Text(
          'This is the Preferences Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}