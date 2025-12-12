import 'package:fine_foods/bottom_navigation.dart';
import 'package:fine_foods/firebase_options.dart';
import 'package:fine_foods/home/printer_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init(); // <-- MUST BE ABOVE!!!

  requestLocationPermission();

  if (!kIsWeb) {
    Get.put(PrinterController(), permanent: true); // now safe
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FINE FOODS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFFD700)),
      ),
      home: BottomNavPage(),
    );
  }
}

Future<void> requestLocationPermission() async {
  var status = await Permission.location.status;

  if (status.isDenied || status.isRestricted) {
    await Permission.location.request();
  }

  // If permanently denied → open app settings
  if (await Permission.location.isPermanentlyDenied) {
    await openAppSettings();
  }
}
