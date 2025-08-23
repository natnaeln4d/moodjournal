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
import 'core/services/connectivity_service.dart';
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
  await Get.putAsync(() => ConnectivityService().init());
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
  final ConnectivityService connectivityService = Get.find<ConnectivityService>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        Obx(() {
          if (authService.user.value != null) {
            return DashboardScreen();
          }
          return LoginScreen();
        }),

        // Modern connectivity indicator
        Obx(() {
          return connectivityService.isConnected.value
              ? SizedBox.shrink()
              : _buildModernConnectionIndicator();
        }),
      ],
    );
  }

  Widget _buildModernConnectionIndicator() {
    return Positioned(
      top: MediaQuery.of(Get.context!).padding.top + 10,
      left: 20,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF6B6B), Color(0xFFEE5A5A)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No internet connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.close,
                color: Colors.white.withOpacity(0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}