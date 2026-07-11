import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class BillsAnalyticsController extends GetxController {
  final totalBills = 0.obs;
  final totalSales = 0.0.obs;
  final totalCash = 0.0.obs;
  final totalOnline = 0.0.obs;
  final quickBillCount = 0.obs;
  final inventoryCount = 0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    isLoading.value = true;
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await FirebaseFirestore.instance
          .collection('bills')
          .where('createdAt',
              isGreaterThanOrEqualTo: thirtyDaysAgo.toIso8601String())
          .orderBy('createdAt', descending: true)
          .get();

      final docs = snapshot.docs;
      developer.log('Fetched ${docs.length} bills for analytics');

      int bills = 0;
      double sales = 0.0;
      double cash = 0.0;
      double online = 0.0;
      int quick = 0;
      int inventory = 0;

      for (final doc in docs) {
        final bill = doc.data();
        bills++;
        sales += (bill['total'] as num).toDouble();
        cash += (bill['cashReceived'] as num?)?.toDouble() ?? 0.0;
        online += (bill['onlineReceived'] as num?)?.toDouble() ?? 0.0;

        final source = bill['source'] ?? 'quickbill';
        if (source == 'quickbill') {
          quick++;
        } else if (source == 'inventory') {
          inventory++;
        }
      }

      totalBills.value = bills;
      totalSales.value = sales;
      totalCash.value = cash;
      totalOnline.value = online;
      quickBillCount.value = quick;
      inventoryCount.value = inventory;

      developer.log(
          'Analytics: bills=$bills, sales=$sales, cash=$cash, online=$online, quick=$quick, inventory=$inventory');
    } catch (e) {
      developer.log('Error fetching analytics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAnalytics() => fetchAnalytics();
}
