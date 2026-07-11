import 'package:fine_foods/ADMIN/invoice_generator/invoice_models.dart';
import 'package:fine_foods/ADMIN/invoice_view/controller/invoice_view_controller.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class InvoiceViewPage extends StatelessWidget {
  final Invoice invoice;

  InvoiceViewPage({super.key, required this.invoice});
  final controller = Get.put(InvoiceViewController());

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Invoice View',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColor.background,
          ),
        ),
        backgroundColor: AppColor.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColor.background),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INVOICE',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Invoice ID: ${invoice.id.substring(0, 8)}',
                          style: GoogleFonts.poppins(
                            color: AppColor.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Date: ${invoice.createdAt.toString().split(' ')[0]}',
                          style: GoogleFonts.poppins(
                            color: AppColor.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Time: ${invoice.createdAt.toString().split(' ')[1].substring(0, 8)}',
                          style: GoogleFonts.poppins(
                            color: AppColor.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 150,
                      maxHeight: 150,
                      minWidth: 100,
                      minHeight: 100,
                    ),
                    child: Image.asset("assets/images/logo.png"),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),

              // Products Table
              Text(
                'Products',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),

              Card(
                elevation: 4,
                color: AppColor.surface,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: AppColor.background,
                      dataTableTheme: DataTableThemeData(
                        headingTextStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                        dataTextStyle: GoogleFonts.poppins(
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Table
                        DataTable(
                          columns: const [
                            DataColumn(label: Text('Product Name')),
                            DataColumn(label: Text('Quantity')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Total')),
                          ],
                          rows: invoice.products.map((product) {
                            return DataRow(
                              cells: [
                                DataCell(Text(product.name)),
                                DataCell(Text('${product.count}')),
                                DataCell(
                                  Text('₹${product.price.toStringAsFixed(2)}'),
                                ),
                                DataCell(
                                  Text(
                                    '₹${product.totalPrice.toStringAsFixed(2)}',
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),

                        // Total Aligned to Table Width
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.end, // aligns with last column
                            children: [
                              Card(
                                elevation: 0,
                                color: AppColor.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: AppColor.primary.withValues(alpha: 0.5)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 24.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'TOTAL: ',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColor.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '₹${invoice.totalAmount.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColor.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final pdfBytes = await controller.generateInvoicePdf(
                        invoice,
                      );
                      await controller.downloadInvoicePdf(
                        pdfBytes,
                        'invoice_${invoice.createdAt}.pdf',
                      );
                      Get.snackbar(
                        'Download Complete',
                        'Invoice saved to Downloads folder',
                        backgroundColor: AppColor.success,
                        colorText: AppColor.textOnPrimary,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.background,
                    ),
                    child: Text(
                      'Download Invoice',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),

                  SizedBox(width: screenWidth * 0.03),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
