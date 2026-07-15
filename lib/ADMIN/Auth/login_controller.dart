import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fine_foods/ADMIN/Auth/auth_controller.dart';
import 'package:fine_foods/appcolor.dart';

class LoginController extends GetxController {
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void _showFeedback(String title, String message, Color bgColor) {
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: bgColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }



  void login(String email, String password) async {

    if (email.isEmpty || password.isEmpty) {
      _showFeedback('Error', 'Please enter email and password', AppColor.error);
      return;
    }

    isLoading.value = true;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _showFeedback('Success', 'Login successful', AppColor.success);
      
      // Navigation or other updates handled via global auth state

      // Update global auth state, which will automatically update UI via Obx
      Get.find<AuthController>().loginSuccess();
    } on FirebaseAuthException catch (e) {
      _showFeedback('Error', e.message ?? 'Invalid credentials', AppColor.error);
    } catch (e) {
      _showFeedback('Error', 'An error occurred during login', AppColor.error);
    } finally {
      isLoading.value = false;
    }
  }
}
