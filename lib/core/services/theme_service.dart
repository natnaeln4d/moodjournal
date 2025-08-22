import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  bool get isDarkMode => _box.read(_key) ?? false;

  void switchTheme() {
    _box.write(_key, !isDarkMode);
  }

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;
}