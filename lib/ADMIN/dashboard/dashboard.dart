import 'package:fine_foods/ADMIN/Inventory/inventary.dart';
import 'package:fine_foods/ADMIN/Stocks/stocks.dart';
import 'package:fine_foods/ADMIN/invoice_generator/invoice_generator.dart';
import 'package:fine_foods/ADMIN/sales_data/Sales_Growth.dart';
import 'package:fine_foods/ADMIN/Bills/billing_list.dart';
import 'package:fine_foods/bottom_navigation.dart';
import 'package:fine_foods/home/home.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // ignore: unused_local_variable
    final screenWidth = MediaQuery.of(context).size.width;

    final List<_DashboardItem> menuItems = [
      _DashboardItem(
        title: "Inventory",
        icon: Icons.inventory_2_rounded,
        color: Colors.blue.shade400,
        page: Inventory(),
      ),
      _DashboardItem(
        title: "Stocks",
        icon: Icons.store_rounded,
        color: Colors.red.shade400,
        page: Stocks(),
      ),
      _DashboardItem(
        title: "Invoice",
        icon: Icons.receipt_long_rounded,
        color: Colors.orange.shade400,
        page: InvoiceGenerator(),
      ),
      _DashboardItem(
        title: "Sales Data",
        icon: Icons.bar_chart_outlined,
        color: Colors.green.shade400,
        page: SalesGrowth(),
      ),
      _DashboardItem(
        title: "Bills",
        icon: Icons.receipt_long_outlined,
        color: const Color.fromARGB(255, 149, 102, 187),
        page: BillingList(),
      ),
    ];

    return WillPopScope(
      onWillPop: () async {
        bool goHome = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Go to Home"),
            content: const Text("Do you want to return to the Home screen?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Get.offAll(() => BottomNavPage()),
                child: const Text("Yes"),
              ),
            ],
          ),
        );

        if (goHome) {
          Get.offAll(() => Home()); // Navigate to Home and clear stack
        }
        return false; // prevent default back action
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Admin Dashboard",
            style: GoogleFonts.oswald(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFFFFD700),
          elevation: 4,
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
              vertical: 12.0,
            ),
            child: Column(
              children: [
                /// 🔹 Logo Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    height: screenHeight * 0.22,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        "assets/images/logo.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                /// 🔹 Welcome Text
                Text(
                  "Welcome, Admin!",
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Manage your business efficiently",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                /// 🔹 Dashboard Menu Grid
                /// 🔹 Dashboard Menu List
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: menuItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // number of columns
                    crossAxisSpacing: 12, // horizontal spacing
                    mainAxisSpacing: 12, // vertical spacing
                    childAspectRatio: 1.2, // width/height ratio
                  ),
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Get.to(() => item.page),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: item.color.withOpacity(0.2),
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
