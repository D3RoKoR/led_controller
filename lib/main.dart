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
  final FlutterBluePlus _ble = FlutterBluePlus.instance;
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

  Future<void> _startScan() async {
    _devices.clear();
    setState(() {});
    await _ble.startScan(timeout: const Duration(seconds: 5));
    _ble.scanResults.listen((results) {
      for (var r in results) {
        _devices[r.device.id] = r;
      }
      setState(() {});
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
    } catch (e) {
      debugPrint('Ошибка подключения: $e');
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

    // Пример команды — замените на формат вашего BLE-контроллера
    final payload = Uint8List.fromList([0x56, red, green, blue, 0x00, 0xF0, 0xAA]);
    try {
      await _writeChar!.write(payload, withoutResponse: true);
    } catch (e) {
      debugPrint('Ошибка при отправке цвета: $e');
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
              onPressed: _startScan,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  Widget _buildScanList() {
    if (_devices.isEmpty) {
      return const Center(child: Text('Сканирование BLE-устройств...'));
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
            'Подключено: ${_connectedDevice!.name.isNotEmpty ? _connectedDevice!.name : _connectedDevice!.id.id}',
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
            label: const Text('Применить цвет'),
            onPressed: _sendColor,
          ),
