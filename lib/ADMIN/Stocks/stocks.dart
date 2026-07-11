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
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Container(
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
                        Container(
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
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.grey[800],
                                dataTableTheme: DataTableThemeData(
                                  headingTextStyle: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.primary,
                                  ),
                                  dataTextStyle: GoogleFonts.poppins(
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                              ),
                              child: DataTable(
                                columnSpacing: 20,
                                dataRowMaxHeight: 56,
                                headingRowHeight: 56,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[800]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      'Name',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Barcode',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Flexible(
                                      child: Text(
                                        'Quantity',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Flexible(
                                      child: Text(
                                        'Unit',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Flexible(
                                      child: Text(
                                        'Price (₹)',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Total',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: controller.products.map((product) {
                                  Color? rowColor;
                                  Icon? statusIcon;
                                  // Simplified robust logic for row colors in dark theme
                                  if (product.count == 0) {
                                    rowColor = AppColor.error.withValues(alpha: 0.1);
                                    statusIcon = const Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppColor.error,
                                      size: 20,
                                    );
                                  } else if (product.count <= 5) {
                                    rowColor = AppColor.warning.withValues(alpha: 0.1);
                                    statusIcon = const Icon(
                                      Icons.error_outline,
                                      color: AppColor.warning,
                                      size: 20,
                                    );
                                  } else {
                                    rowColor = null; // transparent
                                    statusIcon = null;
                                  }

                                  return DataRow(
                                    color: WidgetStateProperty.all(rowColor),
                                    cells: [
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              if (statusIcon != null) ...[
                                                statusIcon,
                                                const SizedBox(width: 8),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  product.name,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: product.count <= 5
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: AppColor.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            product.productId,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: AppColor.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            product.count.toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: product.count <= 5
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: product.count == 0
                                                  ? AppColor.error
                                                  : product.count <= 5
                                                      ? AppColor.warning
                                                      : AppColor.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            product.quantityType,
                                            style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            product.price.toStringAsFixed(2),
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: AppColor.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            product.totalPrice.toStringAsFixed(2),
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: AppColor.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
