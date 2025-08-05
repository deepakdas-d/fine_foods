import 'package:fine_foods/ADMIN/Stocks/stock_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class Stocks extends StatelessWidget {
  const Stocks({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StockAvailabilityController());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stock Availability',
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: const Color(0xFFFFD700),
        centerTitle: true,
        foregroundColor: Colors.black87,
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
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Total Value: ₹${controller.total.value.toStringAsFixed(2)}',
                            style: GoogleFonts.k2d(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 20,
                            dataRowMaxHeight: 56,
                            headingRowHeight: 56,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            columns: [
                              DataColumn(
                                label: Text(
                                  'Name',
                                  style: GoogleFonts.k2d(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Barcode',
                                  style: GoogleFonts.k2d(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Flexible(
                                  child: Text(
                                    'Quantity',
                                    style: GoogleFonts.k2d(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Flexible(
                                  child: Text(
                                    'Unit',
                                    style: GoogleFonts.k2d(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Flexible(
                                  child: Text(
                                    'Price (₹)',
                                    style: GoogleFonts.k2d(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Total',
                                  style: GoogleFonts.k2d(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                            rows: controller.products.map((product) {
                              Color rowColor;
                              Icon? statusIcon;
                              if (product.count == 0) {
                                rowColor = Colors.red[100]!;
                                statusIcon = const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                  size: 20,
                                );
                              } else if (product.count <= 5) {
                                rowColor = Colors.yellow[100]!;
                                statusIcon = const Icon(
                                  Icons.error_outline,
                                  color: Colors.orange,
                                  size: 20,
                                );
                              } else {
                                rowColor = Colors.white;
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
                                              style: GoogleFonts.k2d(
                                                fontSize: 14,
                                                fontWeight: product.count <= 5
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: product.count <= 5
                                                    ? Colors.black87
                                                    : Colors.black54,
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
                                        style: GoogleFonts.k2d(
                                          fontSize: 14,
                                          color: product.count <= 5
                                              ? Colors.black87
                                              : Colors.black54,
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
                                        style: GoogleFonts.k2d(
                                          fontSize: 14,
                                          fontWeight: product.count <= 5
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: product.count == 0
                                              ? Colors.red[800]
                                              : product.count <= 5
                                              ? Colors.orange[800]
                                              : Colors.black54,
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
                                        style: GoogleFonts.k2d(fontSize: 14),
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
                                        style: GoogleFonts.k2d(
                                          fontSize: 14,
                                          color: product.count <= 5
                                              ? Colors.black87
                                              : Colors.black54,
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
                                        style: GoogleFonts.k2d(
                                          fontSize: 14,
                                          color: product.count <= 5
                                              ? Colors.black87
                                              : Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
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
