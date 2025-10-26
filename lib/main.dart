import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const LedControllerApp());
}

class LedControllerApp extends StatelessWidget {
  const LedControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LED Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
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
  StreamSubscription<ScanResult>? _scanSubscription;
  bool _isScanning = false;
  Map<DeviceIdentifier, ScanResult> _devices = {};

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeChar;

  int red = 255;
  int green = 0;
  int blue = 0;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    _devices.clear();
    setState(() => _isScanning = true);

    _scanSubscription = FlutterBluePlus.scan().listen(
      (result) {
        _devices[result.device.id] = result;
        setState(() {});
      },
      onError: (e) {
        debugPrint('Scan error: $e');
        setState(() => _isScanning = false);
      },
      onDone: () => setState(() => _isScanning = false),
    );

    // Остановка сканирования через 5 секунд вручную
    Future.delayed(const Duration(seconds: 5), () {
      _stopScan();
    });
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    setState(() => _isScanning = false);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
    } catch (e) {
      debugPrint('Connection error: $e');
    }

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          _writeChar = characteristic;
          break;
        }
      }
      if (_writeChar != null) break;
    }

    setState(() {
      _connectedDevice = device;
    });
  }

  Future<void> _disconnect() async {
    await _connectedDevice?.disconnect();
    setState(() {
      _connectedDevice = null;
      _writeChar = null;
    });
  }

  Future<void> _sendColor() async {
    if (_writeChar == null) return;
    final payload = Uint8List.fromList([0x56, red, green, blue, 0x00, 0xF0, 0xAA]);
    try {
      await _writeChar!.write(payload, withoutResponse: true);
    } catch (e) {
      debugPrint('Error sending color: $e');
    }
  }

  Widget _buildSlider(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 255,
          divisions: 255,
          label: '$value',
          activeColor: label == 'R'
              ? Colors.red
              : label == 'G'
                  ? Colors.green
                  : Colors.blue,
          onChanged: (v) => onChanged(v.toInt()),
        ),
      ],
    );
  }

  Widget _buildScanList() {
    if (_devices.isEmpty) {
      return const Center(child: Text('Scanning BLE devices...'));
    }

    return ListView(
      children: _devices.values.map((r) {
        final device = r.device;
        final name = device.name.isNotEmpty ? device.name : device.id.id;
        return ListTile(
          title: Text(name),
          subtitle: Text('RSSI: ${r.rssi}'),
          trailing: const Icon(Icons.bluetooth),
          onTap: () => _connectToDevice(device),
        );
      }).toList(),
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Connected: ${_connectedDevice!.name.isNotEmpty ? _connectedDevice!.name : _connectedDevice!.id.id}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSlider('R', red, (v) {
            setState(() => red = v);
            _sendColor();
          }),
          _buildSlider('G', green, (v) {
            setState(() => green = v);
            _sendColor();
          }),
          _buildSlider('B', blue, (v) {
            setState(() => blue = v);
            _sendColor();
          }),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.lightbulb),
            label: const Text('Apply Color'),
            onPressed: _sendColor,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LED Controller'),
        actions: [
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              onPressed: _disconnect,
            ),
        ],
      ),
      body: _connectedDevice == null ? _buildScanList() : _buildControlPanel(),
      floatingActionButton: _connectedDevice == null
          ? FloatingActionButton(
              onPressed: _isScanning ? _stopScan : _startScan,
              child: Icon(_isScanning ? Icons.stop : Icons.refresh),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }
}
