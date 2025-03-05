import 'package:flutter/material.dart';

void main() {
  runApp(CardOrganizerApp());
}

class CardOrganizerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Card Organizer')),
        body: Center(child: Text('Welcome to Card Organizer App!')),
      ),
    );
  }
}