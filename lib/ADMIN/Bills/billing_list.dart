import 'dart:developer';
import 'dart:ui';
import 'package:fine_foods/ADMIN/Bills/billing_list_controller.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:fine_foods/home/bills_analytics_controller.dart';
import 'package:fine_foods/home/bills_analytics_widget.dart';

class BillingList extends StatelessWidget {
  final bool showSourceFilter;
  final bool showAdminActions;
  final String? controllerTag;

  const BillingList({
    super.key,
    this.showSourceFilter = false,
    this.showAdminActions = true,
    this.controllerTag,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BillListController(), tag: controllerTag);
    Get.put(BillsAnalyticsController());

    return Stack(
      children: [
        // MAIN UI
        Scaffold(
          backgroundColor: AppColor.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showAdminActions)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Bills History',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.downloadCurrentReport,
                        icon: const Icon(Icons.download_rounded),
                        tooltip: 'Download Report',
                        style: IconButton.styleFrom(
                          foregroundColor: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: const ExpansionTile(
                  title: Text(
                    'Dashboard Analytics',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  leading: Icon(Icons.analytics_outlined),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: BillsAnalyticsWidget(isCompact: true),
                    ),
                  ],
                ),
              ),
              Obx(() => _buildFilterBar(controller, context)),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.fetchBills(reset: true),
                  child: Obx(() {
                    if (controller.isFetching.value &&
                        controller.bills.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final bills = controller.filteredBills;

                    if (bills.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No bills found',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: AppColor.textSecondary,
                              ),
                            ),
                            if (controller.isSearching && controller.hasMore.value) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => controller.loadMore(),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColor.surface),
                                child: Text('Load older bills to search', style: GoogleFonts.poppins(color: AppColor.primary)),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount:
                          bills.length +
                          (controller.hasMore.value || (controller.isSearching && controller.hasMore.value) ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= bills.length - 5 &&
                            controller.hasMore.value && !controller.isSearching) {
                          controller.loadMore();
                        }

                        if (index == bills.length) {
                          if (!controller.isSearching) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: () => controller.loadMore(),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColor.surface),
                                  child: Text('Load older bills to search', style: GoogleFonts.poppins(color: AppColor.primary)),
                                ),
                              ),
                            );
                          }
                        }

                        return BillCard(
                          bill: bills[index],
                          controller: controller,
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        // 🔵 BLUR + LOADER OVERLAY
        Obx(() {
          if (!controller.isLoading.value) return const SizedBox();

          return Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Generating report...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFilterBar(BillListController controller, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Box
          TextField(
            onChanged: (val) => controller.searchText.value = val,
            style: GoogleFonts.poppins(color: AppColor.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by Invoice No. or Customer...',
              hintStyle: GoogleFonts.poppins(color: AppColor.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColor.textSecondary, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              filled: true,
              fillColor: AppColor.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColor.textSecondary.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColor.textSecondary.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColor.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // ALL
              _buildFilterChip(
                label: 'All Time',
                isSelected: controller.filterType.value == BillFilterType.all,
                onSelected: () => controller.setAllFilter(),
              ),

              // MONTH
              _buildFilterChip(
                label: controller.selectedMonth.value == null
                    ? 'Month'
                    : DateFormat('MMM yyyy').format(controller.selectedMonth.value!),
                isSelected: controller.filterType.value == BillFilterType.month,
                onSelected: () async {
                  final picked = await showMonthPicker(
                    context: context,
                    initialDate: controller.selectedMonth.value ?? DateTime.now(),
                    firstDate: DateTime(2022, 1),
                    lastDate: DateTime.now(),
                  );

                  if (picked != null) {
                    controller.setMonthFilter(DateTime(picked.year, picked.month));
                  }
                },
              ),

              // DAY
              _buildFilterChip(
                label: controller.selectedDay.value == null
                    ? 'Day'
                    : DateFormat('dd MMM yyyy').format(controller.selectedDay.value!),
                isSelected: controller.filterType.value == BillFilterType.day,
                onSelected: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2022),
                    lastDate: DateTime.now(),
                  );

                  if (picked != null) {
                    controller.setDayFilter(picked);
                  }
                },
              ),
            ],
          ),
          if (showSourceFilter) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  label: 'All Sources',
                  isSelected: controller.sourceFilter.value == BillSourceFilter.all,
                  onSelected: () => controller.setSourceFilter(BillSourceFilter.all),
                ),
                _buildFilterChip(
                  label: 'Quick Bill',
                  isSelected: controller.sourceFilter.value == BillSourceFilter.quickbill,
                  onSelected: () => controller.setSourceFilter(BillSourceFilter.quickbill),
                ),
                _buildFilterChip(
                  label: 'Sales Bill',
                  isSelected: controller.sourceFilter.value == BillSourceFilter.inventory,
                  onSelected: () => controller.setSourceFilter(BillSourceFilter.inventory),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onSelected}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColor.primary.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColor.primary : AppColor.textSecondary.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColor.primary : AppColor.textSecondary,
            ),
          ),
        ),
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

    final source = controller.getBillSource(bill);
    final discount = controller.calculateBillDiscount(bill);
    final finalTotal = controller.calculateBillFinalTotal(bill);
    final productRows = _getProductRows();

    return Card(
      elevation: 4,
      color: AppColor.surface, // Dark Card
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
                Flexible(
                  child: Text(
                    invoiceNumber,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColor.textPrimary, // White bold invoice
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: source == 'inventory'
                            ? const Color(0xFF00796B) // Teal
                            : const Color(0xFF455A64), // Blue-gray
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        source == 'inventory' ? 'Sales Bill' : 'Quick Bill',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rs${finalTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppColor.success, // Green Total
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Customer info
            Text(
              'Customer: ${bill['customerName']?.toString().trim().isNotEmpty == true ? bill['customerName'] : 'Walk-in Customer'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColor.textPrimary,
              ),
            ),
            Text(
              'Phone: ${bill['customerPhone']?.toString().trim().isNotEmpty == true ? bill['customerPhone'] : 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColor.textSecondary,
              ),
            ),
            Text(
              'Date: ${DateFormat('MMM dd, yyyy • HH:mm').format(date)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColor.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            // Products title
            Text(
              'Items:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Product list
            if (productRows.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'No items found',
                  style: GoogleFonts.poppins(color: AppColor.textSecondary),
                ),
              )
            else
              ...productRows.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p['name'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: AppColor.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '×${_formatQty(p['qty'])} @ Rs${p['price'].toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: AppColor.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: Text(
                          'Rs${p['total'].toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Discount line
            if (discount > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Discount: -Rs${discount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: AppColor.warning, // Orange for discount
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Download PDF button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await controller.downloadBillPdf(bill);
                  } catch (e, s) {
                    log('[PDF ERROR] $e\n$s');
                    Get.snackbar(
                      'Download Failed',
                      'Could not download PDF. Please try again.',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppColor.error,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 4),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary.withValues(alpha: 0.8),
                  foregroundColor: Colors.black, // Text on primary
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
