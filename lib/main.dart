import 'package:clientapp/login.dart';
import 'package:flutter/material.dart';


void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const title = 'Client App';
    return const MaterialApp(
      title: title,
      home: LoginPage(title: "Connect to Server"),
    );
  }
}