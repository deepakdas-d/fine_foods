import 'package:fine_foods/ADMIN/Inventory/inventary.dart';
import 'package:fine_foods/ADMIN/Stocks/stocks.dart';
import 'package:fine_foods/ADMIN/invoice_generator/invoice_generator.dart';
import 'package:fine_foods/ADMIN/sales_data/sales_growth.dart';
import 'package:fine_foods/ADMIN/Bills/billing_list.dart';
import 'package:fine_foods/ADMIN/DiscountCards/discount_cards_view.dart';
import 'package:fine_foods/ADMIN/Customers/customer_view.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:fine_foods/bottom_navigation.dart';
import 'package:fine_foods/widgets/responsive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fine_foods/home/bills_analytics_widget.dart';
import 'package:fine_foods/home/bills_analytics_controller.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure analytics controller is active
    final analyticsController = Get.put(BillsAnalyticsController());

    final isDesktop = Responsive.isDesktop(context);

    final List<_DashboardItem> menuItems = [
      _DashboardItem(
        title: "Inventory",
        subtitle: "Items & stock levels",
        icon: Icons.inventory_2_rounded,
        color: AppColor.primary,
        page: const Inventory(),
      ),
      _DashboardItem(
        title: "Stocks",
        subtitle: "Track inventory counts",
        icon: Icons.store_rounded,
        color: const Color(0xFFFF9800),
        page: const Stocks(),
      ),
      _DashboardItem(
        title: "Bills History",
        subtitle: "All receipts & invoices",
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF9C27B0),
        page: const BillingList(),
      ),
      _DashboardItem(
        title: "Sales Data",
        subtitle: "Product performance",
        icon: Icons.trending_up_rounded,
        color: AppColor.success,
        page: const SalesGrowth(),
      ),
      _DashboardItem(
        title: "Customers",
        subtitle: "Client accounts & history",
        icon: Icons.people_alt_rounded,
        color: Colors.teal,
        page: CustomerView(),
      ),
      _DashboardItem(
        title: "Discount Cards",
        subtitle: "Membership tier rules",
        icon: Icons.card_giftcard_rounded,
        color: Colors.pinkAccent,
        page: DiscountCardsView(),
      ),
      _DashboardItem(
        title: "Invoice Creator",
        subtitle: "Generate custom invoices",
        icon: Icons.post_add_rounded,
        color: const Color(0xFF2196F3),
        page: const InvoiceGenerator(),
      ),
    ];

    final body = _buildBody(context, isDesktop, menuItems, analyticsController);
    if (isDesktop) return body;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        bool goHome = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColor.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  style: GoogleFonts.poppins(color: AppColor.primary, fontWeight: FontWeight.bold),
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

  Widget _buildBody(
    BuildContext context,
    bool isDesktop,
    List<_DashboardItem> menuItems,
    BillsAnalyticsController analyticsController,
  ) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: AppColor.background,
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
        backgroundColor: AppColor.primary,
        elevation: 0,
        foregroundColor: AppColor.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh Analytics",
            onPressed: () => analyticsController.fetchAnalytics(),
          ),
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              tooltip: "Exit",
              onPressed: () => Get.offAll(() => BottomNavPage()),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Welcome & Status Header
            _buildWelcomeHeader(dateStr, analyticsController),

            const SizedBox(height: 20),

            // 🔹 Quick Access Hub
            _buildQuickAccessSection(context, menuItems),

            const SizedBox(height: 28),

            // 🔹 Analytics Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: AppColor.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "Business Performance",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => analyticsController.fetchAnalytics(),
                  icon: const Icon(Icons.refresh, size: 16, color: AppColor.primary),
                  label: Text(
                    "Reload",
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColor.primary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🔹 Main Analytics (Stat cards, Filters, Donut Chart, Bar Chart)
            const BillsAnalyticsWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String dateStr, BillsAnalyticsController c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.textSecondary.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.surface,
            AppColor.surface.withValues(alpha: 0.8),
            AppColor.primary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Welcome, Admin",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColor.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColor.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColor.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Active",
                            style: GoogleFonts.poppins(
                              color: AppColor.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColor.primary,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context, List<_DashboardItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1100) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 700) {
          crossAxisCount = 3;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Management Hub",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 90,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildModuleCard(item);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildModuleCard(_DashboardItem item) {
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Get.to(() => item.page),
        borderRadius: BorderRadius.circular(16),
        hoverColor: item.color.withValues(alpha: 0.08),
        splashColor: item.color.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.textSecondary.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AppColor.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AppColor.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: Colors.white24,
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
                    child: const Icon(Icons.admin_panel_settings, size: 36, color: AppColor.background),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Admin Menu",
                    style: GoogleFonts.poppins(
                      color: AppColor.background,
                      fontSize: 18,
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
                  subtitle: Text(
                    item.subtitle,
                    style: GoogleFonts.poppins(
                      color: AppColor.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
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
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  _DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}
