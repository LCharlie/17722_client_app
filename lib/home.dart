import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

const String statusOK = "OK";
const String statusFallConfirm = "FALL CONFIRM";
const String statusFallConfirmed = "FALL CONFIRMED";
const String statusHelpNeed = "HELP NEED";
const String statusHelpSent = "HELP SENT";

const double threshold = 5;

class MyHomePage extends StatefulWidget {
  final String userID;
  final Socket channel;
  const MyHomePage({Key? key, required this.userID, required this.channel})
      : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController controller = TextEditingController();
  double velocity = 0;
  double maxVelocity = 0;

  List<double>? _userAccelerometerValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  @override
  void initState() {
    widget.channel.write(widget.userID);
    super.initState();
    monitorAcc();
    sendStatus();
  }

  void monitorAcc() {
    _streamSubscriptions.add(
      userAccelerometerEvents.listen((UserAccelerometerEvent event) {
        setState(() {
          _userAccelerometerValues = <double>[event.x, event.y, event.z];
          velocity = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          if(velocity > maxVelocity) {
            maxVelocity = velocity;
          }
        });
      },
      ),
    );
  }

  void sendStatus() async{
    while(true){
      if(maxVelocity > threshold){
        maxVelocity = 0;
        sendMessage(statusFallConfirm);
        await Future.delayed(const Duration(seconds: 5));
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAccelerometer = _userAccelerometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("User: " + widget.userID),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('UserAccelerometer: $userAccelerometer'),
                ],
              ),
            ),
            Form(
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Send a message'),
              ),
            ),
            StreamBuilder(
              stream: widget.channel,
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      Text(snapshot.hasData
                          ? const Utf8Decoder().convert(snapshot.data as List<int>)
                          : ""),
                      if(snapshot.hasData && const Utf8Decoder().convert(snapshot.data as List<int>) == statusFallConfirm)
                        AlertDialog(
                          title: const Text('Fall detected, need help?'),
                          content: const Text('Staff will be notified.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => sendMessage(statusOK),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => sendMessage(statusHelpNeed),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      if(snapshot.hasData && const Utf8Decoder().convert(snapshot.data as List<int>) == statusHelpSent)
                        AlertDialog(
                          title: const Text('Help is on the way!'),
                          content: const Text(''),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => sendMessage(statusOK),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                    ],
                  )
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => sendMessage(controller.text),
        tooltip: 'Send message',
        child: const Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void sendMessage(String text) {
    if (text.isNotEmpty) {
      widget.channel.write(text);
    }
  }

  @override
  void dispose() {
    widget.channel.close();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}