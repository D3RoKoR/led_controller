import 'package:flutter/material.dart';
import '../services/bluetooth_led_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BluetoothLedService _ledService = BluetoothLedService();

  int red = 255;
  int green = 0;
  int blue = 0;

  bool _connected = false;

  Future<void> _connect() async {
    await _ledService.connect();
    setState(() {
      _connected = true;
    });
  }

  Future<void> _disconnect() async {
    await _ledService.disconnect();
    setState(() {
      _connected = false;
    });
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
          if (_connected)
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              onPressed: _disconnect,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _connected ? null : _connect,
              child: Text(_connected ? 'Connected' : 'Connect'),
            ),
            const SizedBox(height: 16),
            _buildSlider('R', red, (v) {
              setState(() => red = v);
              _ledService.setColor(
                Color.fromARGB(255, red, green, blue),
              );
            }),
            _buildSlider('G', green, (v) {
              setState(() => green = v);
              _ledService.setColor(
                Color.fromARGB(255, red, green, blue),
              );
            }),
            _buildSlider('B', blue, (v) {
              setState(() => blue = v);
              _ledService.setColor(
                Color.fromARGB(255, red, green, blue),
              );
            }),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.lightbulb),
              label: const Text('Apply Color'),
              onPressed: () {
                _ledService.setColor(Color.fromARGB(255, red, green, blue));
              },
            ),
          ],
        ),
      ),
    );
  }
}
