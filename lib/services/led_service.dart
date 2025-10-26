import 'package:flutter/material.dart';

abstract class LedService {
  Color get currentColor;
  double get brightness;

  void setColor(Color color);
  void setBrightness(double value);
}
