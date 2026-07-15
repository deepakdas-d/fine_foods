import 'package:fine_foods/ADMIN/Inventory/inventary.dart';
import 'package:fine_foods/ADMIN/Stocks/stocks.dart';
import 'package:fine_foods/ADMIN/invoice_generator/invoice_generator.dart';
import 'package:fine_foods/ADMIN/sales_data/sales_growth.dart';
import 'package:fine_foods/ADMIN/Bills/billing_list.dart';
import 'package:fine_foods/ADMIN/DiscountCards/discount_cards_view.dart';
import 'package:fine_foods/ADMIN/Customers/customer_view.dart';
import 'package:fine_foods/appcolor.dart'; // Import AppColor
import 'package:fine_foods/bottom_navigation.dart';
import 'package:fine_foods/widgets/responsive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fine_foods/home/bills_analytics_widget.dart';
import 'package:fine_foods/home/bills_analytics_controller.dart';
import 'dashboard_stock_chart.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are available
    Get.put(BillsAnalyticsController());

    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = Responsive.isDesktop(context);

    final List<_DashboardItem> menuItems = [
      _DashboardItem(
        title: "Inventory",
        icon: Icons.inventory_2_rounded,
        color: AppColor.primary, // Yellow
        page: const Inventory(),
      ),
      _DashboardItem(
        title: "Stocks",
        icon: Icons.store_rounded,
        color: const Color(0xFFFF9800), // Orange (Warning/Action)
        page: const Stocks(),
      ),
      _DashboardItem(
        title: "Invoice",
        icon: Icons.receipt_long_rounded,
        color: Colors.blueAccent, // Keep distinct color for invoice
        page: const InvoiceGenerator(),
      ),
      _DashboardItem(
        title: "Sales Data",
        icon: Icons.bar_chart_outlined,
        color: AppColor.success, // Green
        page: const SalesGrowth(),
      ),
      _DashboardItem(
        title: "Bills",
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF9C27B0), // Purple for Bills
        page: const BillingList(),
      ),
      _DashboardItem(
        title: "Customers",
        icon: Icons.people_alt_rounded,
        color: Colors.teal, // Teal for Customers
        page: CustomerView(),
      ),
      _DashboardItem(
        title: "Discount Cards",
        icon: Icons.card_giftcard_rounded,
        color: Colors.pinkAccent, // Pink for Discount Cards
        page: DiscountCardsView(),
      ),
    ];

    // On desktop, the sidebar handles navigation — no WillPopScope needed.
    final body = _buildBody(context, screenHeight, isDesktop, menuItems);
    if (isDesktop) return body;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        bool goHome = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColor.surface,
            title: Text(
              "Go to Home",
              style: GoogleFonts.poppins(
                color: AppColor.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "Do you want to return to the Home screen?",
              style: GoogleFonts.poppins(color: AppColor.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  "No",
                  style: GoogleFonts.poppins(color: AppColor.error),
                ),
              ),
              TextButton(
                onPressed: () => Get.offAll(() => BottomNavPage()),
                child: Text(
                  "Yes",
                  style: GoogleFonts.poppins(color: AppColor.primary),
                ),
              ),
            ],
          ),
        );

        if (goHome) {
          Get.offAll(() => BottomNavPage());
        }
      },
      child: body,
    );
  }

  Widget _buildBody(BuildContext context, double screenHeight, bool isDesktop, List<_DashboardItem> menuItems) {
    return Scaffold(
        backgroundColor: AppColor.background, // Dark Background
        drawer: isDesktop ? null : _buildDrawer(context, menuItems),
        appBar: AppBar(
          title: Text(
            "Admin Dashboard",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColor.background,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColor.primary, // Yellow Header
          elevation: 0,
          foregroundColor: AppColor.background, // Black icons/text on yellow
          actions: [
            if (kIsWeb)
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                onPressed: () {
                  Get.offAll(() => BottomNavPage());
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 Welcome Text
                Text(
                  "Welcome, Admin!",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary, // White
                  ),
                ),
                Text(
                  "Manage your business efficiently",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColor.textSecondary, // Grey
                  ),
                ),
                const SizedBox(height: 24),

                /// 🔹 Dashboard Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column (70%) - Main Analytics
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                BillsAnalyticsWidget(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Right Column (30%) - Top Sales & Low Stock
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                DashboardStockSection(),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          BillsAnalyticsWidget(),
                          SizedBox(height: 24),
                          DashboardStockSection(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildDrawer(BuildContext context, List<_DashboardItem> menuItems) {
    return Drawer(
      backgroundColor: AppColor.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColor.primary,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.background.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings, size: 40, color: AppColor.background),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Admin Menu",
                    style: GoogleFonts.poppins(
                      color: AppColor.background,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return ListTile(
                  leading: Icon(item.icon, color: item.color),
                  title: Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      color: AppColor.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Get.to(() => item.page);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 Model class for dashboard items
class _DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;

  _DashboardItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.page,
  });
}
