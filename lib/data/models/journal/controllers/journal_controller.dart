import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:job5/data/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../journal_model.dart';

class JournalController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  var journals = <JournalEntry>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    ever<AppUser?>(authService.user, (AppUser? user) {
      if (user != null) {
        fetchJournals();
      } else {
        journals.clear();
        isLoading.value = false;
      }
    });

    if (authService.user.value != null) {
      fetchJournals();
    }
  }

  Future<void> addJournal(String title, String content) async {
    isLoading.value = true;
    try {
      final userId = authService.user.value!.id;
      final docRef = firestore.collection('journals').doc();
      final now = DateTime.now();
      final journal = JournalEntry(
        id: docRef.id,
        userId: userId,
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(journal.toMap());
      await fetchJournals(); // This will refresh the list and handle loading state

      Get.snackbar('Success', 'Journal entry added successfully!');
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to add journal: $e');
    }
  }

  Future<void> updateJournal(String id, String title, String content) async {
    isLoading.value = true;
    try {
      await firestore.collection('journals').doc(id).update({
        'title': title,
        'content': content,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update local list immediately for better UX
      final index = journals.indexWhere((journal) => journal.id == id);
      if (index != -1) {
        final updatedJournal = JournalEntry(
          id: id,
          userId: journals[index].userId,
          title: title,
          content: content,
          createdAt: journals[index].createdAt,
          updatedAt: DateTime.now(),
        );
        journals[index] = updatedJournal;
      }

      Get.snackbar('Success', 'Journal entry updated successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update journal: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteJournal(String id) async {
    isLoading.value = true;
    try {
      await firestore.collection('journals').doc(id).delete();

      // Remove from local list immediately
      journals.removeWhere((journal) => journal.id == id);

      Get.snackbar('Success', 'Journal entry deleted successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete journal: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchJournals() async {
    if (authService.user.value == null) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;

    try {
      final userId = authService.user.value!.id;
      final snapshot = await firestore
          .collection('journals')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      journals.assignAll(snapshot.docs.map((doc) => JournalEntry.fromMap(doc.data())));
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch journals: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reloadJournals() async {
    isLoading.value = false;
    await fetchJournals();
  }
}