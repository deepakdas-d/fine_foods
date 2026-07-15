import 'package:fine_foods/ADMIN/Bills/billing_list.dart';
import 'package:fine_foods/ADMIN/Inventory/inventary.dart';
import 'package:fine_foods/ADMIN/Stocks/stocks.dart';
import 'package:fine_foods/ADMIN/dashboard/dashboard.dart';
import 'package:fine_foods/ADMIN/invoice_generator/invoice_generator.dart';
import 'package:fine_foods/ADMIN/sales_data/sales_growth.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:fine_foods/bluetooth_list.dart';
import 'package:fine_foods/home/home.dart';
import 'package:fine_foods/home/user_bills.dart';
import 'package:fine_foods/login.dart';
import 'package:fine_foods/widgets/desktop_nav_controller.dart';
import 'package:fine_foods/widgets/desktop_sidebar.dart';
import 'package:fine_foods/widgets/responsive.dart';
import 'package:fine_foods/SALES/billing/view/billing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fine_foods/ADMIN/Auth/auth_controller.dart';

/// Top-level desktop layout shell.
///
/// Renders [DesktopSidebar] on the left and the currently selected
/// content page on the right, constrained to [Responsive.maxContentWidth].
///
/// This widget replaces [BottomNavPage] on screens wider than 800px.
class DesktopShell extends StatelessWidget {
  DesktopShell({super.key});

  final DesktopNavController controller = Get.find<DesktopNavController>();

  /// Maps sidebar indices to their corresponding page widgets.
  Widget _pageForIndex(int index) {
    // If the index corresponds to an admin section (1 to 6) and the user
    // is not logged in, render the LoginPage instead of the requested page.
    if (index >= 1 && index <= 6 && !Get.find<AuthController>().isAdminLoggedIn.value) {
      return LoginPage();
    }

    switch (index) {
      case 0:
        return Home();
      case 1:
        return const Dashboard();
      case 2:
        return const Inventory();
      case 3:
        return const Stocks();
      case 4:
        return const InvoiceGenerator();
      case 5:
        return const SalesGrowth();
      case 6:
        return const BillingList();
      case 7:
        if (!kIsWeb) return const BluetoothList();
        return Home(); // fallback — shouldn't reach on web
      case 8:
        return const UserBills();
      case 9:
        return BillingScreen();
      default:
        return Home();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Row(
        children: [
          // ── Sidebar ──
          DesktopSidebar(),

          // ── Content Area ──
          Expanded(
            child: Obx(() {
              final page = _pageForIndex(controller.selectedIndex.value);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Center(
                  key: ValueKey(controller.selectedIndex.value),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Responsive.maxContentWidth,
                    ),
                    child: page,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
