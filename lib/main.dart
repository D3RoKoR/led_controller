import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BLE Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterBluePlus _flutterBlue = FlutterBluePlus();
  late StreamSubscription<List<ScanResult>> _scanSubscription;
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
  }

  void _startScan() {
    _scanResults.clear();
    setState(() {
      _isScanning = true;
    });

    _scanSubscription = _flutterBlue.startScan(
      timeout: const Duration(seconds: 5),
    ).listen(
      (scanResults) {
        setState(() {
          _scanResults = scanResults;
        });
      },
      onDone: () {
        setState(() {
          _isScanning = false;
        });
      },
      onError: (e) {
        setState(() {
          _isScanning = false;
        });
        print('Scan error: $e');
      },
    );
  }

  void _stopScan() {
    _scanSubscription.cancel();
    setState(() {
      _isScanning = false;
    });
  }

  @override
  void dispose() {
    _scanSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter BLE Demo'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _isScanning ? _stopScan : _startScan,
            child: Text(_isScanning ? 'Stop Scan' : 'Start Scan'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final result = _scanResults[index];
                return ListTile(
                  title: Text(result.device.name.isEmpty
                      ? result.device.id.id
                      : result.device.name),
                  subtitle: Text('RSSI: ${result.rssi}'),
                  onTap: () {
                    // Handle device tap
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
