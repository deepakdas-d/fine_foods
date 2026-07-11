import 'package:fine_foods/ADMIN/Inventory/inventary.dart';
import 'package:fine_foods/ADMIN/Stocks/stocks.dart';
import 'package:fine_foods/ADMIN/invoice_generator/invoice_generator.dart';
import 'package:fine_foods/ADMIN/sales_data/sales_growth.dart';
import 'package:fine_foods/ADMIN/Bills/billing_list.dart';
import 'package:fine_foods/appcolor.dart'; // Import AppColor
import 'package:fine_foods/bottom_navigation.dart';
import 'package:fine_foods/widgets/responsive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
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
                /// 🔹 Logo Card
                // Card(
                //   elevation: 8,
                //   color: AppColor.surface,
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(16),
                //   ),
                //   child: Container(
                //     height: screenHeight * 0.22,
                //     width: double.infinity,
                //     padding: const EdgeInsets.all(16),
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(16),
                //       color: AppColor.surface,
                //     ),
                //     child: Center(
                //       child: Image.asset(
                //         "assets/images/logo.png",
                //         fit: BoxFit.contain,
                //       ),
                //     ),
                //   ),
                // ),
                // SizedBox(height: screenHeight * 0.03),

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
                SizedBox(height: screenHeight * 0.03),

                /// 🔹 Dashboard Menu Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: menuItems.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 1.3 : 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return Card(
                      elevation: 4,
                      color: AppColor.surface, // Dark Card Background
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Get.to(() => item.page),
                        splashColor: item.color.withValues(alpha: 0.1),
                        highlightColor: item.color.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 32,
                                  color: item.color,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textPrimary, // White text
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
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
