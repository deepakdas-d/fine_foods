import 'package:fine_foods/ADMIN/Inventory/inventary.dart';
import 'package:fine_foods/ADMIN/Stocks/stocks.dart';
import 'package:fine_foods/ADMIN/invoice_generator/invoice_generator.dart';
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
        color: Colors.green.shade400,
        page: Stocks(),
      ),
      _DashboardItem(
        title: "Invoice",
        icon: Icons.receipt_long_rounded,
        color: Colors.orange.shade400,
        page: InvoiceGenerator(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Admin Dashboard",
          style: GoogleFonts.oswald(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD700),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      onTap: () => Get.to(() => item.page),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: item.color.withOpacity(0.2),
                        child: Icon(item.icon, size: 32, color: item.color),
                      ),
                      title: Text(
                        item.title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.grey[400],
                        size: 18,
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
