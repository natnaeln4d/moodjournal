// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:job5/data/models/dashboard/controllers/mood_controller.dart'; // Make sure this is imported
import 'package:job5/data/models/journal/controllers/journal_controller.dart';
import 'package:job5/modules/journal/views/journal_list_screen.dart';
import 'package:job5/themes.dart';

import 'core/bindings/theme_controller.dart';
import 'core/services/auth_service.dart';
import 'core/services/theme_service.dart';
import 'modules/auth/controllers/auth_controller.dart';
import 'modules/dashboard/views/dashboard_screen.dart';
import 'modules/views/login_screen.dart';

// Import the new DashboardBinding
import 'modules/dashboard/bindings/dashboard_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();

  Get.put(AuthService());
  Get.put(AuthController());
  Get.put(JournalController());
  Get.put(ThemeService());
  Get.put(ThemeController());
  Get.put(MoodController());

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  final ThemeController _themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => GetMaterialApp(
      title: 'Mood Tracker',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeController.themeMode.value,
      home: RootWidget(),
    ));
  }
}

class RootWidget extends StatelessWidget {
  final AuthService authService = Get.find<AuthService>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (authService.user.value != null) {
        return DashboardScreen();
      }
      return LoginScreen();
    });
  }
}