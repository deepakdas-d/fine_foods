import 'package:fine_foods/bottom_navigation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final isAdminLoggedIn = false.obs;
  final GetStorage _storage = Get.find<GetStorage>();

  @override
  void onInit() {
    super.onInit();
    // Seed isAdminLoggedIn synchronously from GetStorage on app startup
    isAdminLoggedIn.value = _storage.read('loggedIn') ?? false;

    // Listen to FirebaseAuth.instance.authStateChanges() on app startup to sync states
    if (Firebase.apps.isNotEmpty) {
      try {
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
          if (user == null) {
            // Do not aggressively logout here; rely on local GetStorage state
            // to persist admin login across app restarts on platforms where
            // Firebase Auth persistence might be delayed or unavailable.
          } else {
            // If Firebase Auth has a logged in user, sync local state
            if (!isAdminLoggedIn.value) {
              loginSuccess();
            }
          }
        });
      } catch (e) {
        debugPrint("Error listening to authStateChanges: $e");
      }
    }
  }

  void loginSuccess() {
    _storage.write('loggedIn', true);
    isAdminLoggedIn.value = true;
  }

  void logout() async {
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint("Error signing out: $e");
      }
    }
    _storage.remove('loggedIn');
    isAdminLoggedIn.value = false;
    
    // Route back to home if currently anywhere else
    Get.offAll(() => BottomNavPage());
  }
}

