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

// <-- your controller file

class BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final BillListController controller;

  const BillCard({super.key, required this.bill, required this.controller});

  @override
  Widget build(BuildContext context) {
    // -----------------------------------------------------------------
    // 1. Parse date & invoice number
    // -----------------------------------------------------------------
    final date = DateTime.parse(bill['createdAt']).toLocal();
    final invoiceNumber =
        bill['invoiceNumber'] ?? 'INV-${bill['id'].substring(0, 8)}';

    // -----------------------------------------------------------------
    // 2. Totals (subtotal, discount, final total)
    // -----------------------------------------------------------------
    // ignore: unused_local_variable
    final subtotal = controller.calculateBillSubtotal(bill);
    final discount = controller.calculateBillDiscount(bill);
    final finalTotal = controller.calculateBillFinalTotal(bill);

    // -----------------------------------------------------------------
    // 3. Helper to extract product rows (same logic as PDF)
    // -----------------------------------------------------------------
    List<Map<String, dynamic>> _productRows() {
      final List<Map<String, dynamic>> rows = [];

      final products = bill['products'];
      if (products == null) return rows;

      // ---- Map format (new) ----
      if (products is Map) {
        for (var p in products.values) {
          if (p is Map) {
            rows.add({
              'name': p['productName']?.toString() ?? '',
              'qty': (p['quantity'] as num?)?.toDouble() ?? 0.0,
              'price': (p['price'] as num?)?.toDouble() ?? 0.0,
              'total': (p['total'] as num?)?.toDouble() ?? 0.0,
            });
          }
        }
      }
      // ---- Array format (old) ----
      else if (products is List) {
        for (var p in products) {
          if (p is Map) {
            rows.add({
              'name': p['productName']?.toString() ?? '',
              'qty': (p['quantity'] as num?)?.toDouble() ?? 0.0,
              'price': (p['price'] as num?)?.toDouble() ?? 0.0,
              'total': (p['total'] as num?)?.toDouble() ?? 0.0,
            });
          }
        }
      }
      return rows;
    }

    final productRows = _productRows();

    // -----------------------------------------------------------------
    // 4. UI
    // -----------------------------------------------------------------
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----- Header (Invoice + Final Total) -----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invoice: $invoiceNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Rs${finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ----- Customer & Date -----
            Text(
              'Customer: ${bill['customerName'] ?? 'Walk-in Customer'}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Phone: ${bill['customerPhone']?.toString().isNotEmpty == true ? bill['customerPhone'] : 'N/A'}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(date)}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // ----- Products -----
            const Text(
              'Products:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),

            if (productRows.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('No items', style: TextStyle(color: Colors.grey)),
              )
            else
              ...productRows.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    top: 2.0,
                    bottom: 2.0,
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: '${p['name']} ',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text:
                              '(x${p['qty'].toStringAsFixed(p['qty'] % 1 == 0 ? 0 : 1)}) ',
                        ),
                        TextSpan(
                          text:
                              '- Rs${p['price'].toStringAsFixed(2)}  →  Rs${p['total'].toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ----- Discount (if any) -----
            if (discount > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Discount: -Rs${discount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                ),
              ),

            const SizedBox(height: 12),

            // ----- Download Button -----
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    log('[LOG] Downloading PDF for ${bill['id']}...');
                    await controller.downloadBillPdf(bill);
                  } catch (e, stack) {
                    log('[ERROR] PDF download failed: $e');
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
                icon: const Icon(Icons.download, size: 20),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
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
