import 'package:fine_foods/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sales_growth_controller.dart';

class SalesGrowth extends StatelessWidget {
  const SalesGrowth({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesGrowthController());

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "Sales Growth",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColor.background,
          ),
        ),
        backgroundColor: AppColor.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColor.background),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.productSales.isEmpty) {
          return Center(
            child: Text(
              "No sales data available.",
              style: GoogleFonts.poppins(color: AppColor.textSecondary),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: AppColor.surface,
              dataTableTheme: DataTableThemeData(
                headingRowColor: WidgetStateProperty.all(AppColor.surface),
                headingTextStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColor.primary,
                ),
                dataTextStyle: GoogleFonts.poppins(
                  color: AppColor.textPrimary,
                ),
              ),
            ),
            child: DataTable(
              columns: const [
                DataColumn(
                  label: Text("Product Name"),
                ),
                DataColumn(
                  label: Text("Total Quantity Sold"),
                ),
                DataColumn(
                  label: Text("Total Quantity"),
                ),
                DataColumn(
                  label: Text("Remaining Stock"),
                ),
              ],
              rows: controller.productSales.map((entry) {
                return DataRow(
                  cells: [
                    DataCell(Text(entry.name)),
                    DataCell(Text(entry.soldQty.toString())),
                    DataCell(Text(entry.inventoryQty.toString())),
                    DataCell(
                      Text(
                        entry.remainingQty.toString(),
                        style: GoogleFonts.poppins(
                          color: entry.remainingQty < 10
                              ? AppColor.error
                              : AppColor.textPrimary,
                          fontWeight: entry.remainingQty < 10
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      }),
    );
  }
}
