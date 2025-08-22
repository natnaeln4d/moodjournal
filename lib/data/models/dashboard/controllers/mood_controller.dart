import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:job5/data/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../mood_model.dart';

class MoodController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  var moods = <Mood>[].obs;
  var isLoading = false.obs;
  var selectedMood = 'neutral'.obs;

  var streakCount = 0.obs;
  var totalEntries = 0.obs;
  var badges = <String>[].obs;

  @override
  void onInit() {
    super.onInit();

    ever<AppUser?>(authService.user, (AppUser? user) {
      if (user != null) {
        fetchUserMoods();
      } else {
        moods.clear();
        streakCount.value = 0;
        totalEntries.value = 0;
        badges.clear();
      }
    });

    if (authService.user.value != null) {
      fetchUserMoods();
    }
  }

  Future<void> addMoodEntry(String moodType, {String? note}) async {
    isLoading.value = true;
    try {
      final userId = authService.user.value!.id;
      final docRef = firestore.collection('moods').doc();

      final mood = Mood(
        id: docRef.id,
        userId: userId,
        moodType: moodType,
        timestamp: DateTime.now(),
        note: note,
      );

      await docRef.set(mood.toMap());

      moods.insert(0, mood);
      totalEntries.value++;

      _updateStreakAndAchievements();
      await reloadMoods();

      Get.snackbar(
        'Success',
        'Your mood was logged successfully! You\'ve made ${totalEntries.value} entries.',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to log mood: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserMoods() async {
    isLoading.value = true;
    try {
      final userId = authService.user.value!.id;
      final snapshot = await firestore
          .collection('moods')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      moods.assignAll(snapshot.docs.map((doc) => Mood.fromMap(doc.data())));
      totalEntries.value = moods.length;

      _updateStreakAndAchievements();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch moods: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteMoodEntry(String moodId) async {
    try {
      await firestore.collection('moods').doc(moodId).delete();
      moods.removeWhere((mood) => mood.id == moodId);
      totalEntries.value--;
      _updateStreakAndAchievements();


      await reloadMoods();
      Get.snackbar(
        'Success',
        'Mood entry deleted.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete mood: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _updateStreakAndAchievements() {
    _calculateStreak();
    _checkForAchievements();
  }

  void _calculateStreak() {
    if (moods.isEmpty) {
      streakCount.value = 0;
      return;
    }

    int currentStreak = 0;
    final uniqueDates = moods.map((m) => DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day)).toSet().toList();
    uniqueDates.sort((a, b) => b.compareTo(a));

    DateTime lastDate = DateTime.now();
    bool isTodayLogged = uniqueDates.any((date) => date.day == lastDate.day && date.month == lastDate.month && date.year == lastDate.year);

    if (isTodayLogged) {
      currentStreak = 1;
      lastDate = lastDate.subtract(const Duration(days: 1));
    } else {
      streakCount.value = 0;
      return;
    }


    for (int i = 0; i < uniqueDates.length - 1; i++) {
      final currentDate = uniqueDates[i];
      final previousDate = uniqueDates[i + 1];
      final difference = currentDate.difference(previousDate).inDays;
      if (difference == 1) {
        currentStreak++;
      } else {
        break;
      }
    }
    streakCount.value = currentStreak;
  }

  void _checkForAchievements() {

    if (totalEntries.value >= 5 && !badges.contains('Five-Time Logger')) {
      badges.add('Five-Time Logger');
      Get.snackbar(
        'Achievement Unlocked!',
        'You\'ve logged 5 entries!',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    if (streakCount.value >= 3 && !badges.contains('Streak Master')) {
      badges.add('Streak Master');
      Get.snackbar(
        'Achievement Unlocked!',
        'You\'ve maintained a 3-day streak!',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

  }
  Future<void> reloadMoods() async {
    await fetchUserMoods();
  }
}