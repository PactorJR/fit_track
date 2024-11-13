import 'package:flutter/material.dart';

class MemberBenefitsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Members Benefits'),
      ),
      body: Center(
        child: Text(
          'This is the Members Benefits',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}