import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'led_service.dart';

class BluetoothLedService implements LedService {
  Color _color = Colors.red;
  double _brightness = 1.0;

  final String deviceName;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;

  BluetoothLedService({required this.deviceName});

  @override
  Color get currentColor => _color;

  @override
  double get brightness => _brightness;

  Future<void> connect() async {
    FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

    final scanSubscription = flutterBlue.scan(timeout: const Duration(seconds: 5)).listen((scanResult) {
      if (scanResult.device.name == deviceName) {
        _device = scanResult.device;
      }
    });

    await scanSubscription.asFuture();
    await scanSubscription.cancel();

    if (_device != null) {
      await _device!.connect();
      List<BluetoothService> services = await _device!.discoverServices();
      _characteristic = services.first.characteristics.first;
    }
  }

  @override
  void setColor(Color color) {
    _color = color;
    _sendCommand();
  }

  @override
  void setBrightness(double value) {
    _brightness = value;
    _sendCommand();
  }

  void _sendCommand() async {
    if (_characteristic != null) {
      int r = (_color.red * _brightness).round();
      int g = (_color.green * _brightness).round();
      int b = (_color.blue * _brightness).round();
      List<int> data = [r, g, b];
      try {
        await _characteristic!.write(data, withoutResponse: true);
      } catch (e) {
        print("Bluetooth write error: $e");
      }
    }
  }
}
