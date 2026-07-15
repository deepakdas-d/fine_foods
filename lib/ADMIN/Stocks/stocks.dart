import 'package:fine_foods/ADMIN/Stocks/stock_controller.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class Stocks extends StatelessWidget {
  const Stocks({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StockAvailabilityController());

    return Scaffold(
      backgroundColor: AppColor.background, // Dark Background
      appBar: AppBar(
        title: Text(
          'Stock Availability',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24, color: AppColor.background),
        ),
        backgroundColor: AppColor.primary, // Yellow
        centerTitle: true,
        foregroundColor: AppColor.background,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(color: AppColor.surface, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColor.primary.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'Total Value: ₹${controller.total.value.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        onChanged: controller.onSearchChanged,
                        style: GoogleFonts.poppins(color: AppColor.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(color: AppColor.textSecondary),
                          prefixIcon: const Icon(Icons.search, color: AppColor.primary),
                          filled: true,
                          fillColor: AppColor.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(
                  () {
                    // Force Obx to track the products list.
                    // LayoutBuilder accesses the list during layout phase, which hides it from Obx tracking.
                    final _ = controller.products.length;
                    
                    return controller.isLoading.value
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 600) {
                                return _buildDesktopTable(controller, context);
                              } else {
                                return _buildMobileList(controller, context);
                              }
                            },
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

  Widget _buildDesktopTable(StockAvailabilityController controller, BuildContext context) {
    return Container(
      width: double.infinity,
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
                Expanded(flex: 3, child: Text('Name', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                Expanded(flex: 2, child: Text('Barcode', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                Expanded(flex: 2, child: Text('Quantity', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                Expanded(flex: 1, child: Text('Unit', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                Expanded(flex: 2, child: Text('Price (₹)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                Expanded(flex: 2, child: Text('Total', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
              ],
            ),
          ),
          ...controller.products.asMap().entries.map((entry) {
            int idx = entry.key;
            var product = entry.value;

            Color? rowColor;
            Icon? statusIcon;
            if (product.count == 0) {
              rowColor = AppColor.error.withValues(alpha: 0.1);
              statusIcon = const Icon(Icons.warning_amber_rounded, color: AppColor.error, size: 20);
            } else if (product.count <= 5) {
              rowColor = AppColor.warning.withValues(alpha: 0.1);
              statusIcon = const Icon(Icons.error_outline, color: AppColor.warning, size: 20);
            }

            return Material(
              color: rowColor ?? (idx.isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.02)),
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
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            if (statusIcon != null) ...[statusIcon, const SizedBox(width: 8)],
                            Expanded(
                              child: Text(
                                product.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColor.textPrimary,
                                  fontWeight: product.count <= 5 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text(product.productId, style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textSecondary))),
                      Expanded(
                        flex: 2, 
                        child: Text(
                          product.count.toString(), 
                          style: GoogleFonts.poppins(
                            fontSize: 14, 
                            fontWeight: product.count <= 5 ? FontWeight.bold : FontWeight.normal,
                            color: product.count == 0 ? AppColor.error : (product.count <= 5 ? AppColor.warning : AppColor.textPrimary),
                          )
                        )
                      ),
                      Expanded(flex: 1, child: Text(product.quantityType, style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary))),
                      Expanded(flex: 2, child: Text(product.price.toStringAsFixed(2), style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary))),
                      Expanded(flex: 2, child: Text(product.totalPrice.toStringAsFixed(2), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColor.textPrimary))),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileList(StockAvailabilityController controller, BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.products.length,
      itemBuilder: (context, index) {
        final product = controller.products[index];
        
        Color borderColor = Colors.grey[800]!;
        Icon? statusIcon;
        if (product.count == 0) {
          borderColor = AppColor.error;
          statusIcon = const Icon(Icons.warning_amber_rounded, color: AppColor.error, size: 20);
        } else if (product.count <= 5) {
          borderColor = AppColor.warning;
          statusIcon = const Icon(Icons.error_outline, color: AppColor.warning, size: 20);
        }

        return Card(
          color: AppColor.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: product.count <= 5 ? 1.5 : 1.0),
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
                      child: Row(
                        children: [
                          if (statusIcon != null) ...[statusIcon, const SizedBox(width: 8)],
                          Expanded(
                            child: Text(
                              product.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColor.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Barcode: ${product.productId}",
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Qty", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                        Text(
                          "${product.count} ${product.quantityType}", 
                          style: GoogleFonts.poppins(
                            fontSize: 14, 
                            color: product.count == 0 ? AppColor.error : (product.count <= 5 ? AppColor.warning : AppColor.textPrimary), 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Price", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                        Text("₹${product.price.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Total", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                        Text("₹${product.totalPrice.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.primary)),
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
