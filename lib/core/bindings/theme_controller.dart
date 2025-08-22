import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/theme_service.dart';

class ThemeController extends GetxController {
  final ThemeService _themeService = ThemeService();

  var themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();

    themeMode.value = _themeService.themeMode;
  }

  void toggleTheme() {
    _themeService.switchTheme();
    themeMode.value = _themeService.themeMode;
    Get.changeThemeMode(themeMode.value);
  }
}