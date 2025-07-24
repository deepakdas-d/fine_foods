import 'package:fine_foods/invoice_generator/models/invoice_models.dart';
import 'package:fine_foods/invoice_view/controller/invoice_view_controller.dart';
import 'package:fine_foods/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      appBar: buildAppbar(
        title: Text('Invoice View'),
        color: Color(0xFFFFD700),
        forecolor: Colors.black,
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
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text('Invoice ID: ${invoice.id.substring(0, 8)}'),
                        Text(
                          'Date: ${invoice.createdAt.toString().split(' ')[0]}',
                        ),
                        Text(
                          'Time: ${invoice.createdAt.toString().split(' ')[1].substring(0, 8)}',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  ConstrainedBox(
                    constraints: BoxConstraints(
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),

              Card(
                elevation: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
                              elevation: 4,
                              color: Colors.green[50],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 24.0,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'TOTAL: ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      '₹${invoice.totalAmount.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
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
                      );
                    },
                    child: Text('Download Invoice'),
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
