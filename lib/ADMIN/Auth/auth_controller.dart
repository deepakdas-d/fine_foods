import 'package:fine_foods/bottom_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController with WidgetsBindingObserver {
  final isAdminLoggedIn = false.obs;
  final GetStorage _storage = GetStorage('GetStorage');
  final int sessionTimeoutHours = 8;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _checkSession();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSession();
    }
  }

  void _checkSession() {
    final bool loggedIn = _storage.read('loggedIn') ?? false;
    final String? timestampStr = _storage.read('timestamp');

    if (loggedIn && timestampStr != null) {
      final DateTime timestamp = DateTime.parse(timestampStr);
      final Duration difference = DateTime.now().difference(timestamp);

      // Verify timestamp is within limit AND Firebase user is actually logged in
      if (difference.inHours < sessionTimeoutHours &&
          FirebaseAuth.instance.currentUser != null) {
        isAdminLoggedIn.value = true;
        return;
      }
    }

    // If we reach here, session is invalid or expired
    if (isAdminLoggedIn.value || loggedIn) {
      logout();
    }
  }

  void loginSuccess() {
    _storage.write('loggedIn', true);
    _storage.write('timestamp', DateTime.now().toIso8601String());
    isAdminLoggedIn.value = true;
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    _storage.remove('loggedIn');
    _storage.remove('timestamp');
    isAdminLoggedIn.value = false;
    
    // Route back to home if currently anywhere else
    Get.offAll(() => BottomNavPage());
  }
}
