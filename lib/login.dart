import 'dart:io';
import 'package:clientapp/home.dart';
import 'package:flutter/material.dart';

const int port = 65432;

class LoginPage extends StatefulWidget {
  final String title;
  const LoginPage({Key? key, required this.title})
      : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  late final Socket channel;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              controller: ipController,
              decoration: const InputDecoration(labelText: 'Server IP'),
            ),
            TextFormField(
              controller: idController,
              decoration: const InputDecoration(labelText: 'User ID'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          connectServer();
        },
        child: const Icon(Icons.login),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void connectServer() async{
    try {
      channel = await Socket.connect(ipController.text, port);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage(userID: idController.text, channel: channel)),
      );
    } on Exception catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connection failed'),
          content: Text(e.toString()),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'))
          ],
        ),
      );
    }
  }
}