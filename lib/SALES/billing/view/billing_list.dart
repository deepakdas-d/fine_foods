import 'dart:developer';
import 'package:fine_foods/SALES/billing/controller/billing_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BillingList extends StatelessWidget {
  const BillingList({super.key});

  @override
  Widget build(BuildContext context) {
    final BillListController controller = Get.put(BillListController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill History'),
        elevation: 0,
        backgroundColor: const Color(0xFFFFD700),
        actions: [
          IconButton(
            onPressed: () async {
              final bills = controller.bills;
              if (bills.isEmpty) {
                Get.snackbar(
                  'Error',
                  'No bills available to generate PDF',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              await controller.downloadMonthlyReport(bills.toList());
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
  final BillListController controller;

  const BillCard({super.key, required this.bill, required this.controller});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(bill['createdAt']).toLocal();
    final total = controller.calculateBillSubtotal(bill);
    final invoiceNumber =
        bill['invoiceNumber'] ?? 'INV-${bill['id'].substring(0, 8)}';

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
                  'Invoice: $invoiceNumber',
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
            Text('Customer: ${bill['customerName'] ?? 'Walk-in Customer'}'),
            Text('Phone: ${bill['customerPhone'] ?? 'N/A'}'),
            Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(date)}'),
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
                    '${product['productName']} (x${product['quantity']}) - \$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
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
                    log('[LOG] Downloading bill PDF for ${bill['id']}...');
                    await controller.downloadBillPdf(bill);
                  } catch (e, stack) {
                    log('[ERROR] Failed to download PDF: $e');
                    log('[STACK] $stack');
                    Get.snackbar(
                      'Error',
                      'Failed to download PDF: $e',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
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
