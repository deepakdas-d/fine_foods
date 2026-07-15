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
        actions: [
          Obx(() => DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: AppColor.surface,
              icon: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.filter_list, color: AppColor.background),
              ),
              value: controller.selectedFilter.value,
              style: GoogleFonts.poppins(color: AppColor.background, fontWeight: FontWeight.w600),
              selectedItemBuilder: (BuildContext context) {
                return ['Today', 'This Month', 'This Year', 'All Time'].map((String value) {
                  return Center(
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(color: AppColor.background, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList();
              },
              items: ['Today', 'This Month', 'This Year', 'All Time'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(color: AppColor.textPrimary, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.changeFilter(newValue);
                }
              },
            ),
          )),
          const SizedBox(width: 16),
        ],
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

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return _buildDesktopTable(controller, context);
            } else {
              return _buildMobileList(controller, context);
            }
          },
        );
      }),
    );
  }

  Widget _buildDesktopTable(SalesGrowthController controller, BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColor.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Product Name', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                  Expanded(flex: 2, child: Text('Total Quantity Sold', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                  Expanded(flex: 2, child: Text('Total Quantity', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                  Expanded(flex: 2, child: Text('Remaining Stock', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                ],
              ),
            ),
            ...controller.productSales.asMap().entries.map((entryMap) {
              int idx = entryMap.key;
              var entry = entryMap.value;
              return Material(
                color: idx.isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.02),
                child: InkWell(
                  hoverColor: AppColor.primary.withValues(alpha: 0.1),
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(entry.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.textPrimary))),
                        Expanded(flex: 2, child: Text(entry.soldQty.toString(), style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary))),
                        Expanded(flex: 2, child: Text(entry.inventoryQty.toString(), style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary))),
                        Expanded(
                          flex: 2, 
                          child: Text(
                            entry.remainingQty.toString(), 
                            style: GoogleFonts.poppins(
                              fontSize: 14, 
                              color: entry.remainingQty < 10 ? AppColor.error : AppColor.textPrimary,
                              fontWeight: entry.remainingQty < 10 ? FontWeight.bold : FontWeight.normal,
                            )
                          )
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList(SalesGrowthController controller, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.productSales.length,
      itemBuilder: (context, index) {
        final entry = controller.productSales[index];
        bool isLow = entry.remainingQty < 10;
        
        return Card(
          color: AppColor.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isLow ? AppColor.error : Colors.grey[800]!, width: isLow ? 1.5 : 1.0),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                    if (isLow)
                      const Icon(Icons.warning_amber_rounded, color: AppColor.error, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Sold", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                        Text("${entry.soldQty}", style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                        Text("${entry.inventoryQty}", style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Remaining", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                        Text(
                          "${entry.remainingQty}", 
                          style: GoogleFonts.poppins(
                            fontSize: 15, 
                            fontWeight: FontWeight.bold, 
                            color: isLow ? AppColor.error : AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
