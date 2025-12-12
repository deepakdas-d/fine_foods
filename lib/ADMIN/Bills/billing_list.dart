import 'dart:developer';
import 'package:fine_foods/ADMIN/Bills/billing_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BillingList extends StatelessWidget {
  const BillingList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BillListController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final month = controller.selectedMonth.value;
          return Text(
            month != null
                ? 'Bills - ${DateFormat('MMMM yyyy').format(month)}'
                : 'All Bills History',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          );
        }),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        elevation: 2,
        actions: [
          // Month Dropdown Filter
          Padding(
            padding: const EdgeInsets.only(right: 16),
            // child: Center(
            //   child: Obx(
            //     () => DropdownButton<DateTime?>(
            //       value: controller.selectedMonth.value,
            //       hint: const Text(
            //         'All Time',
            //         style: TextStyle(color: Colors.black87),
            //       ),
            //       icon: const Icon(Icons.calendar_month, color: Colors.black87),
            //       underline: const SizedBox(),
            //       style: const TextStyle(
            //         color: Colors.black87,
            //         fontSize: 16,
            //         fontWeight: FontWeight.w600,
            //       ),
            //       dropdownColor: Colors.amber.shade50,
            //       borderRadius: BorderRadius.circular(12),
            //       items: [
            //         const DropdownMenuItem(
            //           value: null,
            //           child: Text('All Time'),
            //         ),
            //         ...controller.getMonthOptions().map(
            //           (date) => DropdownMenuItem(
            //             value: date,
            //             child: Text(DateFormat('MMMM yyyy').format(date)),
            //           ),
            //         ),
            //       ],
            //       onChanged: (DateTime? newValue) {
            //         controller.selectedMonth.value = newValue;
            //         controller.fetchBills(reset: true);
            //       },
            //     ),
            //   ),
            // ),
          ),

          // Download Button
          IconButton(
            onPressed: controller.downloadCurrentReport,
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download Report',
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          // Total Sales Card (only when month selected)
          Obx(() {
            if (controller.selectedMonth.value == null)
              return const SizedBox(height: 8);
            final total = controller.bills.fold<double>(
              0.0,
              (sum, bill) => sum + controller.calculateBillFinalTotal(bill),
            );
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Sales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rs${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Bills List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.fetchBills(reset: true),
              child: Obx(() {
                if (controller.isLoading.value && controller.bills.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.bills.isEmpty) {
                  return Center(
                    child: Text(
                      controller.selectedMonth.value == null
                          ? 'No bills found'
                          : 'No bills in ${DateFormat('MMMM yyyy').format(controller.selectedMonth.value!)}',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount:
                      controller.bills.length +
                      (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Load more
                    if (index >= controller.bills.length - 5 &&
                        controller.hasMore.value) {
                      controller.loadMore();
                    }

                    if (index == controller.bills.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final bill = controller.bills[index];
                    return BillCard(bill: bill, controller: controller);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final BillListController controller;

  const BillCard({super.key, required this.bill, required this.controller});

  // Helper to safely extract product rows (supports both old array & new map format)
  List<Map<String, dynamic>> _getProductRows() {
    final List<Map<String, dynamic>> rows = [];

    final products = bill['products'];
    if (products == null) return rows;

    Iterable<MapEntry<String, dynamic>> entries;

    if (products is Map) {
      entries = (products).entries.map((e) => MapEntry(e.key, e.value));
    } else if (products is List) {
      entries = products.asMap().entries.map(
        (e) => MapEntry(e.key.toString(), e.value),
      );
    } else {
      return rows;
    }

    for (var entry in entries) {
      final p = entry.value;
      if (p is Map<String, dynamic>) {
        final qty = (p['quantity'] as num?)?.toDouble() ?? 0.0;
        final price = (p['price'] as num?)?.toDouble() ?? 0.0;
        final total = (p['total'] as num?)?.toDouble() ?? (qty * price);

        rows.add({
          'name': p['productName']?.toString().trim().isNotEmpty == true
              ? p['productName'].toString()
              : 'Unknown Item',
          'qty': qty,
          'price': price,
          'total': total,
        });
      }
    }

    return rows;
  }

  // Format quantity: show as int if whole number
  String _formatQty(double qty) {
    return qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    // Safely parse date
    DateTime date;
    try {
      date = DateTime.parse(bill['createdAt'] as String).toLocal();
    } catch (e) {
      date = DateTime.now();
    }

    final invoiceNumber = bill['invoiceNumber']?.toString().isNotEmpty == true
        ? bill['invoiceNumber'].toString()
        : 'INV-${bill['id'].toString().substring(0, 8).toUpperCase()}';

    final discount = controller.calculateBillDiscount(bill);
    final finalTotal = controller.calculateBillFinalTotal(bill);
    final productRows = _getProductRows();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Invoice + Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  invoiceNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Rs${finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Customer info
            Text(
              'Customer: ${bill['customerName']?.toString().trim().isNotEmpty == true ? bill['customerName'] : 'Walk-in Customer'}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Phone: ${bill['customerPhone']?.toString().trim().isNotEmpty == true ? bill['customerPhone'] : 'N/A'}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Date: ${DateFormat('MMM dd, yyyy • HH:mm').format(date)}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Products title
            const Text(
              'Items:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),

            // Product list
            if (productRows.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  'No items found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...productRows.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p['name'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '×${_formatQty(p['qty'])} @ Rs${p['price'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rs${p['total'].toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Discount line
            if (discount > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Discount: -Rs${discount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Download PDF button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    log('[PDF] Starting download for bill ${bill['id']}');
                    await controller.downloadBillPdf(bill);
                  } catch (e, s) {
                    log('[PDF ERROR] $e\n$s');
                    Get.snackbar(
                      'Download Failed',
                      'Could not download PDF. Please try again.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.shade600,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 4),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
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
