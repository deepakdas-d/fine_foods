import 'package:fine_foods/bottom_navigation.dart';
import 'package:fine_foods/firebase_options.dart';
import 'package:fine_foods/home/home_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  requestLocationPermission();
  Get.put(PrinterController(), permanent: true);

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
