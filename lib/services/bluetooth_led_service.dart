import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../led_service.dart';

class BluetoothLedService implements LedService {
  Color _color = Colors.red;
  double _brightness = 1.0;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;

  BluetoothLedService();

  @override
  Color get currentColor => _color;

  @override
  double get brightness => _brightness;

  // Сканирование и подключение к первому найденному устройству с любым именем
  Future<void> connect({String? deviceName}) async {
    await for (final scanResult in FlutterBluePlus.instance.scanForDevices(
      timeout: const Duration(seconds: 5),
    )) {
      if (deviceName == null || scanResult.device.name == deviceName) {
        _device = scanResult.device;
        break;
      }
    }

    if (_device != null) {
      await _device!.connect(autoConnect: false, license: License.free);
      final services = await _device!.discoverServices();
      if (services.isNotEmpty) {
        _characteristic = services.first.characteristics.first;
      }
    } else {
      debugPrint("Device not found");
    }
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
    _characteristic = null;
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
    if (_characteristic == null) return;

    int r = (_color.red * _brightness).round();
    int g = (_color.green * _brightness).round();
    int b = (_color.blue * _brightness).round();
    final data = Uint8List.fromList([0x56, r, g, b, 0x00, 0xF0, 0xAA]);

    try {
      await _characteristic!.write(data, withoutResponse: true);
      debugPrint("Sent data: $data");
    } catch (e) {
      debugPrint("Write error: $e");
    }
  }
}
