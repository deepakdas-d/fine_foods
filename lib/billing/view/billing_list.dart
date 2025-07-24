import 'dart:developer';

import 'package:fine_foods/billing/controller/billing_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';

class BillingList extends StatelessWidget {
  const BillingList({super.key});

  @override
  Widget build(BuildContext context) {
    final BillingController controller = Get.put(BillingController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill History'),
        elevation: 0,
        backgroundColor: Color(0xFFFFD700),
        actions: [
          IconButton(
            onPressed: () async {
              final bills = controller.bills;

              if (bills.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No bills available to generate PDF'),
                  ),
                );
                return;
              }

              try {
                final pdfBytes = await controller.generateMonthlyBillPdf(bills);
                final date = DateTime.now();
                final fileName =
                    'monthly_bill_${date.year}_${date.month.toString().padLeft(2, '0')}.pdf';

                final filePath = await controller.saveBillPdfToDownloads(
                  pdfBytes,
                  fileName,
                );

                final result = await OpenFile.open(filePath);
                if (result.type == ResultType.done) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF saved to Downloads and opened'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to open PDF: ${result.message}'),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to generate or open PDF: $e')),
                );
              }
            },

            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : controller.bills.isEmpty
            ? const Center(child: Text('No bills found'))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: controller.bills.length,
                itemBuilder: (context, index) {
                  final bill = controller.bills[index];
                  return BillCard(bill: bill, controller: controller);
                },
              ),
      ),
    );
  }
}

class BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final BillingController controller;

  const BillCard({super.key, required this.bill, required this.controller});

  // Calculate total for both new and old bill formats
  double calculateBillTotal(Map<String, dynamic> bill) {
    if (bill['total'] != null && bill['total'] is num) {
      return (bill['total'] as num).toDouble();
    }
    double total = 0;
    if (bill['products'] != null && bill['products'] is Map) {
      bill['products'].values.forEach((product) {
        total += (product['price'] as num) * (product['quantity'] as num);
      });
    } else if (bill['price'] != null && bill['price'] is num) {
      // Handle old bill format with single product
      total = (bill['price'] as num).toDouble();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(bill['createdAt']).toLocal();
    final total = calculateBillTotal(bill);
    final BillingController controller = Get.put(BillingController());

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bill ID: ${bill['id'].substring(0, 8)}...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Customer: ${bill['customerName']}'),
            Text('Phone: ${bill['customerPhone']}'),
            Text('Date: ${date.toString().substring(0, 16)}'),
            const SizedBox(height: 8),
            Text(
              'Products:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (bill['products'] != null && bill['products'] is Map)
              ...bill['products'].values.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text(
                    '${product['productName']} (x${product['quantity']}) - \$${product['price'].toStringAsFixed(2)}',
                  ),
                ),
              )
            else if (bill['productName'] != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Text(
                  '${bill['productName']} (x1) - \$${bill['price']?.toStringAsFixed(2) ?? '0.00'}',
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    log('[LOG] Generating bill PDF...');
                    final pdfBytes = await controller.generateBillPdf(bill);

                    final fileName = 'bill_${bill['id']}.pdf';
                    await controller.saveBillPdfToDownloads(pdfBytes, fileName);
                  } catch (e, stack) {
                    log('[ERROR] Failed to generate/download PDF: $e');
                    log('[STACK] $stack');
                  }
                },

                icon: const Icon(Icons.download),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
