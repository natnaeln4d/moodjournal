import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../data/models/user_model.dart';

class AuthController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  var isLoading = false.obs;

  @override
  void onInit() {
    ever(authService.user, (AppUser? user) {
      if (user != null) {

        log('User signed in: ${user.email}');
      } else {
        log('User signed out');
      }
    });
    super.onInit();
  }

  Future<void> signUp(String email, String password) async {
    isLoading.value = true;
    try {
      await authService.signUpWithEmail(email, password);

    } catch (e) {
      _handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signIn(String email, String password) async {
    isLoading.value = true;
    try {
      await authService.signInWithEmail(email, password);

    } catch (e) {
      _handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _handleError(dynamic error) {
    String errorMessage = 'An error occurred';

    if (error is FirebaseAuthException) {
      errorMessage = _getFirebaseAuthErrorMessage(error);
      log('Firebase Auth Error: ${error.code} - $errorMessage');
    } else if (error is TypeError) {
      errorMessage = 'Authentication service error. Please try again.';
      log('Type Error: $error');
    } else if (error.toString().contains('No internet connection')) {
      errorMessage = 'No internet connection. Please check your network settings.';
    } else {
      errorMessage = error.toString();
      if (errorMessage.length > 100) {
        errorMessage = errorMessage.substring(0, 100) + '...';
      }
      log('Auth Error: $error');
    }

    Get.snackbar(
      'Error',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email address is already in use by another account.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
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