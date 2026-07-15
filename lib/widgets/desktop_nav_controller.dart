import 'package:get/get.dart';

/// Navigation state for the desktop sidebar.
///
/// Tracks which content page is currently displayed in the desktop shell.
/// Purely UI state — no business logic.
class DesktopNavController extends GetxController {
  /// Index of the currently selected sidebar item.
  ///
  /// 0 = Home (Quick Bill)
  /// 1 = Dashboard (Admin overview grid)
  /// 2 = Inventory
  /// 3 = Stocks
  /// 4 = Invoice Generator
  /// 5 = Sales Growth
  /// 6 = Bills (Admin)
  /// 7 = Bluetooth / Printer (hidden on web)
  /// 8 = Bills (User)
  /// 9 = Sales Bill
  final selectedIndex = 0.obs;

  /// Tracks whether the user is logged into the admin section on desktop.
  final isLoggedIn = false.obs;
}
