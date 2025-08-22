import 'package:get/get.dart';

import '../../../data/models/dashboard/controllers/mood_controller.dart';


class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MoodController());
  }
}