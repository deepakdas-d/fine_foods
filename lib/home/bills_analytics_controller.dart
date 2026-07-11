import 'dart:developer' as developer;
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

enum AnalyticsSourceFilter { all, quickbill, inventory }
enum AnalyticsPaymentFilter { all, cash, online }
enum AnalyticsDateFilter { today, week, month, custom }

class BillsAnalyticsController extends GetxController {
  final totalBills = 0.obs;
  final totalSales = 0.0.obs;
  final totalCash = 0.0.obs;
  final totalOnline = 0.0.obs;
  final quickBillCount = 0.obs;
  final inventoryCount = 0.obs;
  final isLoading = false.obs;

  // Filters
  final sourceFilter = AnalyticsSourceFilter.all.obs;
  final paymentFilter = AnalyticsPaymentFilter.all.obs;
  final dateFilter = AnalyticsDateFilter.month.obs;
  final customDateRange = Rx<DateTimeRange?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    isLoading.value = true;
    try {
      DateTime now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;

      switch (dateFilter.value) {
        case AnalyticsDateFilter.today:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case AnalyticsDateFilter.week:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case AnalyticsDateFilter.month:
          startDate = now.subtract(const Duration(days: 30));
          break;
        case AnalyticsDateFilter.custom:
          if (customDateRange.value != null) {
            startDate = customDateRange.value!.start;
            endDate = customDateRange.value!.end.add(const Duration(days: 1)); // Include the end day
          } else {
            startDate = now.subtract(const Duration(days: 30)); // fallback
          }
          break;
      }

      Query query = FirebaseFirestore.instance.collection('bills');

      // Date range filter
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String());

      // Source filter
      if (sourceFilter.value == AnalyticsSourceFilter.quickbill) {
        query = query.where('source', isEqualTo: 'quickbill');
      } else if (sourceFilter.value == AnalyticsSourceFilter.inventory) {
        query = query.where('source', isEqualTo: 'inventory');
      }

      // Payment filter (paymentMethod can be 'Cash', 'Online', 'Both')
      // If 'Both' (Split), it technically involves both.
      // If we strictly filter by 'Cash', we only get full cash payments. 
      // This is a known limitation of exact string matching unless we check 'Cash' or 'Both'.
      // For simplicity matching the request:
      if (paymentFilter.value == AnalyticsPaymentFilter.cash) {
        query = query.where('paymentMethod', whereIn: ['Cash', 'Both']);
      } else if (paymentFilter.value == AnalyticsPaymentFilter.online) {
        query = query.where('paymentMethod', whereIn: ['Online', 'Both']);
      }

      query = query.orderBy('createdAt', descending: true);

      // We limit to 500 to avoid massive client-side aggregation overhead if the date range is huge.
      query = query.limit(500);

      final snapshot = await query.get();

      final docs = snapshot.docs;
      developer.log('Fetched ${docs.length} bills for analytics');

      int bills = 0;
      double sales = 0.0;
      double cash = 0.0;
      double online = 0.0;
      int quick = 0;
      int inventory = 0;

      for (final doc in docs) {
        final bill = doc.data() as Map<String, dynamic>;
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

  void setSourceFilter(AnalyticsSourceFilter filter) {
    sourceFilter.value = filter;
    fetchAnalytics();
  }

  void setPaymentFilter(AnalyticsPaymentFilter filter) {
    paymentFilter.value = filter;
    fetchAnalytics();
  }

  void setDateFilter(AnalyticsDateFilter filter, {DateTimeRange? customRange}) {
    dateFilter.value = filter;
    if (customRange != null) {
      customDateRange.value = customRange;
    }
    fetchAnalytics();
  }
}
