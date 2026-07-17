import 'package:fine_foods/appcolor.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fine_foods/bottom_navigation.dart';
import 'package:fine_foods/firebase_options.dart';
import 'package:fine_foods/home/printer_controller.dart';
import 'package:fine_foods/widgets/desktop_nav_controller.dart';
import 'package:fine_foods/ADMIN/Auth/auth_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  GetStorage storage;
  if (!kIsWeb) {
    final appDir = await getApplicationSupportDirectory();
    storage = GetStorage('GetStorage', appDir.path);
    await storage.initStorage;
  } else {
    await GetStorage.init('GetStorage');
    storage = GetStorage('GetStorage');
  }
  Get.put<GetStorage>(storage, permanent: true);
  requestLocationPermission();

  // PrinterController moved to InitialBinding to ensure Overlay is ready
  // Get.put(PrinterController(), permanent: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: BindingsBuilder(() {
        if (!kIsWeb) {
          Get.put(PrinterController(), permanent: true);
        }
        Get.put(AuthController(), permanent: true);
        Get.lazyPut(() => DesktopNavController());
      }),
      title: 'FINE FOODS',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColor.background,
        primaryColor: AppColor.primary,
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: AppColor.textPrimary,
              displayColor: AppColor.textPrimary,
            ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColor.primary,
          brightness: Brightness.dark,
          surface: AppColor.surface,
          primary: AppColor.primary,
          onPrimary: AppColor.textOnPrimary,
          error: AppColor.error,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColor.background,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: AppColor.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: AppColor.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColor.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColor.surface,
          labelStyle: TextStyle(color: AppColor.textSecondary),
          hintStyle: TextStyle(color: AppColor.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColor.textSecondary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColor.textSecondary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColor.primary),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: AppColor.textOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: AppColor.textPrimary),
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
