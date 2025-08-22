import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  var isLoading = false.obs;

  Future<void> signUp(String email, String password) async {
    isLoading.value = true;
    await authService.signUpWithEmail(email, password);
    isLoading.value = false;
  }

  Future<void> signIn(String email, String password) async {
    isLoading.value = true;
    await authService.signInWithEmail(email, password);
    isLoading.value = false;
  }

  Future<void> updateUserProfile(String displayName, String? photoUrl) async {
    if (authService.user.value != null) {
      final updatedUser = authService.user.value!.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      await authService.updateUser(updatedUser);
    }
  }

  Future<void> addUserPoints(int points) async {
    await authService.addPoints(points);
  }

  Future<void> signOut() async {
    await authService.signOut();
  }
}