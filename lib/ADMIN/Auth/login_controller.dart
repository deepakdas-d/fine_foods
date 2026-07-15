import 'package:fine_foods/ADMIN/dashboard/dashboard.dart';
import 'package:fine_foods/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fine_foods/ADMIN/Auth/auth_controller.dart';
import 'package:fine_foods/appcolor.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

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
      
      // Clear text fields on successful login
      emailController.clear();
      passwordController.clear();

      // Update global auth state, which will automatically update UI via Obx
      Get.find<AuthController>().loginSuccess();
      
      // Mobile needs explicit routing if not handled by Obx in BottomNav
      if (!Responsive.isDesktop(Get.context!)) {
        Get.offAll(() => const Dashboard()); 
      }
    } on FirebaseAuthException catch (e) {
      _showFeedback('Error', e.message ?? 'Invalid credentials', AppColor.error);
    } catch (e) {
      _showFeedback('Error', 'An error occurred during login', AppColor.error);
    } finally {
      isLoading.value = false;
    }
  }
}
