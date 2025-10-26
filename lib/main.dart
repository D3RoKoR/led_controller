import 'package:flutter/material.dart';
import 'ui/home_page.dart';
import 'services/bluetooth_led_service.dart';
import 'services/led_service.dart';

void main() {
  runApp(MyApp(
    ledService: BluetoothLedService(deviceName: "LED_LAMP_01"),
  ));
}

class MyApp extends StatelessWidget {
  final LedService ledService;
  const MyApp({super.key, required this.ledService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LED Controller',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(ledService: ledService),
    );
  }
}
