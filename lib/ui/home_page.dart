import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/led_service.dart';

class HomePage extends StatefulWidget {
  final LedService ledService;
  const HomePage({super.key, required this.ledService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Color selectedColor = Colors.red;
  double brightness = 1.0;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.ledService.currentColor;
    brightness = widget.ledService.brightness;
  }

  void _changeColor(Color color) {
    setState(() => selectedColor = color);
    widget.ledService.setColor(color);
  }

  void _changeBrightness(double value) {
    setState(() => brightness = value);
    widget.ledService.setBrightness(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LED Controller')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: _changeColor,
              showLabel: true,
              pickerAreaHeightPercent: 0.6,
            ),
            const SizedBox(height: 20),
            Text("Brightness: ${(brightness * 100).round()}%"),
            Slider(
              value: brightness,
              min: 0.0,
              max: 1.0,
              divisions: 100,
              onChanged: _changeBrightness,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await (widget.ledService as BluetoothLedService).connect();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connected to LED device!')),
                );
              },
              child: const Text('Connect to LED'),
            ),
          ],
        ),
      ),
    );
  }
}
