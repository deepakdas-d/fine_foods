import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:fine_foods/home/user_bills_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fine_foods/home/bills_analytics_widget.dart';
import 'package:fine_foods/home/bills_analytics_controller.dart';
import 'package:fine_foods/home/quickbill_controller.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:fine_foods/ADMIN/Bills/billing_list_controller.dart';

class UserBills extends StatelessWidget {
  const UserBills({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserBillsController());
    Get.put(BillsAnalyticsController());

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text(
          'My Bills',
          style: TextStyle(color: AppColor.textPrimary),
        ),
        backgroundColor: AppColor.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textPrimary),
      ),
      body: Obx(() {
        final bills = controller.filteredBills;

        return RefreshIndicator(
          onRefresh: controller.refreshBills,
          color: AppColor.primary,
          backgroundColor: AppColor.surface,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: const ExpansionTile(
                        title: Text(
                          'Dashboard Analytics',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                        ),
                        leading: Icon(Icons.analytics_outlined, color: AppColor.textPrimary),
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: BillsAnalyticsWidget(isCompact: true),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        onChanged: (val) => controller.searchText.value = val,
                        style: const TextStyle(color: AppColor.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search by Invoice or Customer',
                          hintStyle: const TextStyle(color: AppColor.textSecondary),
                          prefixIcon: const Icon(Icons.search, color: AppColor.textSecondary),
                          filled: true,
                          fillColor: AppColor.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Obx(() => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFilterChip(
                                  'All Time',
                                  controller.filterType.value == BillFilterType.all,
                                  () => controller.setAllFilter(),
                                ),
                                _buildFilterChip(
                                  controller.selectedMonth.value == null
                                      ? 'Month'
                                      : DateFormat('MMM yyyy').format(controller.selectedMonth.value!),
                                  controller.filterType.value == BillFilterType.month,
                                  () async {
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
                                _buildFilterChip(
                                  controller.selectedDay.value == null
                                      ? 'Day'
                                      : DateFormat('dd MMM yyyy').format(controller.selectedDay.value!),
                                  controller.filterType.value == BillFilterType.day,
                                  () async {
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
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFilterChip(
                                  'All Payments',
                                  controller.paymentFilter.value == AnalyticsPaymentFilter.all,
                                  () => controller.setPaymentFilter(AnalyticsPaymentFilter.all),
                                ),
                                _buildFilterChip(
                                  'Cash',
                                  controller.paymentFilter.value == AnalyticsPaymentFilter.cash,
                                  () => controller.setPaymentFilter(AnalyticsPaymentFilter.cash),
                                ),
                                _buildFilterChip(
                                  'Online',
                                  controller.paymentFilter.value == AnalyticsPaymentFilter.online,
                                  () => controller.setPaymentFilter(AnalyticsPaymentFilter.online),
                                ),
                                _buildFilterChip(
                                  'Split',
                                  controller.paymentFilter.value == AnalyticsPaymentFilter.split,
                                  () => controller.setPaymentFilter(AnalyticsPaymentFilter.split),
                                ),
                              ],
                            ),
                          ],
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.isLoading.value && controller.bills.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColor.primary)),
                )
              else if (bills.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No bills found.',
                          style: TextStyle(color: AppColor.textSecondary),
                        ),
                        if (controller.isSearching && controller.hasMore.value) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => controller.loadMore(),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColor.surface),
                            child: const Text('Load older bills to search', style: TextStyle(color: AppColor.primary)),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == bills.length) {
                          if (controller.isLoadingMore.value) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColor.primary),
                              ),
                            );
                          } else if (controller.isSearching && controller.hasMore.value) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: () => controller.loadMore(),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColor.surface),
                                  child: const Text('Load older bills to search', style: TextStyle(color: AppColor.primary)),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        // Lazy loading trigger (only auto-fetch if NOT searching)
                        if (index == bills.length - 1 && !controller.isSearching) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            controller.loadMore();
                          });
                        }

                        final bill = bills[index];
                        return _buildBillCard(bill, controller);
                      },
                      childCount: bills.length +
                          (controller.isLoadingMore.value || (controller.isSearching && controller.hasMore.value) ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onSelected) {
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColor.primary : AppColor.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill, UserBillsController controller) {
    final isQuickBill = bill['source'] == 'quickbill';
    final invoiceNumber = bill['invoiceNumber'] ?? 'INV-${bill['id'].toString().substring(0, 8)}';
    final customerName = bill['customerName'] ?? 'Walk-in Customer';
    final date = _parseDate(bill['createdAt']);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    final total = _calculateTotal(bill);

    return Card(
      color: AppColor.surface,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoiceNumber,
                        style: const TextStyle(
                          color: AppColor.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customerName,
                        style: const TextStyle(
                          color: AppColor.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppColor.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isQuickBill ? const Color(0xFF455A64) : const Color(0xFF00796B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isQuickBill ? 'Quick Bill' : 'Inventory Sale',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColor.background, thickness: 1),
            const SizedBox(height: 8),
            _buildProductsList(bill),
            const SizedBox(height: 8),
            const Divider(color: AppColor.background, thickness: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: Rs${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColor.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        final qc = Get.put(QuickbillController());
                        qc.printInvoice(bill);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColor.textSecondary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.print, color: AppColor.textPrimary, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Print',
                              style: TextStyle(
                                color: AppColor.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => controller.downloadPdf(bill),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColor.textSecondary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download, color: AppColor.textPrimary, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'PDF',
                          style: TextStyle(
                            color: AppColor.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(Map<String, dynamic> bill) {
    final List<Map<String, dynamic>> products = _extractProductRows(bill);
    return Column(
      children: products.map((p) {
        final name = p['name'] ?? 'Unknown Item';
        final numQty = p['quantity'] as num? ?? 0;
        final qtyStr = numQty % 1 == 0 ? numQty.toInt().toString() : numQty.toStringAsFixed(1);
        final price = p['price'] ?? 0;
        final total = p['total'] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '×$qtyStr @ Rs${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColor.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 60,
                child: Text(
                  'Rs${total.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _extractProductRows(Map<String, dynamic> bill) {
    final List<Map<String, dynamic>> rows = [];
    final products = bill['products'];
    if (products == null) return rows;

    Iterable<dynamic> items = [];
    if (products is Map) {
      items = products.values;
    } else if (products is List) {
      items = products;
    }

    for (var p in items) {
      if (p is Map) {
        rows.add({
          'name': p['productName']?.toString().isNotEmpty == true
              ? p['productName']
              : 'Unknown Item',
          'quantity': (p['quantity'] as num?)?.toDouble() ?? 0.0,
          'price': (p['price'] as num?)?.toDouble() ?? 0.0,
          'total': (p['total'] as num?)?.toDouble() ?? 0.0,
        });
      }
    }
    return rows;
  }

  double _calculateTotal(Map<String, dynamic> bill) {
    double total = 0.0;
    final products = bill['products'];
    if (products is Map) {
      for (var p in products.values) {
        if (p is Map) {
          total += (p['total'] as num?)?.toDouble() ?? 0.0;
        }
      }
    } else if (products is List) {
      for (var p in products) {
        if (p is Map) {
          total += (p['total'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    final discount = (bill['discount'] as num?)?.toDouble() ?? 0.0;
    return (total - discount).clamp(0.0, double.infinity);
  }

  DateTime _parseDate(dynamic createdAt) {
    if (createdAt is Timestamp) return createdAt.toDate().toLocal();
    if (createdAt is String) return DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now();
    return DateTime.now();
  }
}
