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
      title: 'Led Controller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  final List<BluetoothDevice> _devices = [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    // Запуск сканирования BLE-устройств
    _flutterBlue.startScan(timeout: const Duration(seconds: 5));

    _flutterBlue.scanResults.listen((results) async {
      for (var result in results) {
        if (!_devices.contains(result.device)) {
          setState(() {
            _devices.add(result.device);
          });
        }
      }
    });

    _flutterBlue.isScanning.listen((scanning) {
      if (!scanning) {
        _flutterBlue.stopScan();
      }
    });
  }

  void _connect(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false, license: License.free);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LED Controller')),
      body: ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          return ListTile(
            title: Text(device.name.isNotEmpty ? device.name : device.id.id),
            trailing: ElevatedButton(
              onPressed: () => _connect(device),
              child: const Text('Connect'),
            ),
          );
        },
      ),
    );
  }
}
