import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StockAvailabilityController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final products = <Product>[].obs;
  final allProducts = <Product>[];
  final isLoading = false.obs;
  
  final tableKey = GlobalKey<PaginatedDataTableState>();
  
  final total = 0.0.obs;

  Timer? _debounce;
  final searchQuery = ''.obs;

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchQuery.value = query;
      _filterProducts();
    });
  }

  void _filterProducts() {
    if (searchQuery.value.isEmpty) {
      products.assignAll(allProducts);
    } else {
      final q = searchQuery.value.toLowerCase();
      products.assignAll(
        allProducts.where((p) => p.name.toLowerCase().contains(q)).toList(),
      );
    }
    // calculateTotal() is intentionally removed here so search doesn't override the overall database total
  }

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> fetchOverallTotal() async {
    try {
      final allDocs = await _firestore.collection('products').get();
      double calculatedTotal = 0.0;
      for (var doc in allDocs.docs) {
        final data = doc.data();
        final qty = (data['count'] as num?)?.toInt() ?? 0;
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
        calculatedTotal += qty * price;
      }
      total.value = calculatedTotal;
    } catch (e) {
      debugPrint('Error fetching overall total: $e');
    }
  }

  DocumentSnapshot? lastDocument;
  final hasMore = true.obs;
  final isFetchingNextPage = false.obs;
  static const int pageSize = 20;

  void loadProducts({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isFetchingNextPage.value || !hasMore.value) return;
      isFetchingNextPage.value = true;
    } else {
      if (isLoading.value) return;
      isLoading.value = true;
      lastDocument = null;
      hasMore.value = true;
      allProducts.clear();
      products.clear();
      fetchOverallTotal();
    }

    try {
      Query query = _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        lastDocument = querySnapshot.docs.last;
      }

      if (querySnapshot.docs.length < pageSize) {
        hasMore.value = false;
      }

      final newProducts = querySnapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>)).toList();
      
      for (var p in newProducts) {
        if (!allProducts.any((existing) => existing.id == p.id)) {
          allProducts.add(p);
        }
      }

      _filterProducts();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load products: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (isLoadMore) {
        isFetchingNextPage.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }
}
