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
    final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

    // Сканируем устройства
    await for (final scanResult in flutterBlue.scan(timeout: const Duration(seconds: 5))) {
      if (scanResult.device.name == deviceName) {
        _device = scanResult.device;
        break;
      }
    }

    if (_device != null) {
      // Подключаемся с обязательным параметром license
      await _device!.connect(
          autoConnect: false, 
          timeout: const Duration(seconds: 5), 
          license: "MIT");

      final services = await _device!.discoverServices();
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
        print("Bluetooth: Sent $data");
      } catch (e) {
        print("Bluetooth write error: $e");
      }
    }
  }
}
