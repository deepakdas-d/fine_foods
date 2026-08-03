import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StockAvailabilityController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final products = <Product>[].obs;
  final allProducts = <Product>[]; // Store paginated products for browse mode
  final isLoading = false.obs;
  final isSearching = false.obs;
  final isCalculatingTotal = false.obs;

  /// One-time cache of ALL products for global search
  final List<Product> _allProductsCache = [];
  bool _allProductsFetched = false;
  Future<void>? _cacheFuture;

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

  /// Fetches ALL products into cache (one-time cost).
  Future<void> _ensureAllProductsCached() async {
    if (_allProductsFetched) return;
    if (_cacheFuture != null) {
      await _cacheFuture;
      return;
    }

    _cacheFuture = _fetchAndCacheAllProducts();
    await _cacheFuture;
    _cacheFuture = null;
  }

  Future<void> _fetchAndCacheAllProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();
      _allProductsCache.clear();
      _allProductsCache.addAll(
        snapshot.docs
            .map((doc) => Product.fromMap(doc.data()))
            .toList(),
      );
      // Sync paginated allProducts with the full cache
      allProducts.clear();
      allProducts.addAll(_allProductsCache);
      // Compute total from cache (avoids a separate full-collection read)
      total.value = _allProductsCache.fold(
        0.0, (acc, p) => acc + p.totalPrice,
      );
      _allProductsFetched = true;
    } catch (e) {
      debugPrint('Error caching all products: $e');
    }
  }

  Future<void> _filterProducts() async {
    if (searchQuery.value.isEmpty) {
      products.assignAll(allProducts);
    } else {
      // Global search: cache all products first, then filter client-side
      isSearching.value = !_allProductsFetched;
      try {
        await _ensureAllProductsCached();
        final q = searchQuery.value.toLowerCase();
        products.assignAll(
          _allProductsCache.where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.productId.contains(q)
          ).toList(),
        );
      } finally {
        isSearching.value = false;
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> fetchOverallTotal() async {
    try {
      isCalculatingTotal.value = true;
      if (_allProductsFetched) {
        // Calculate from cache — no network call needed
        total.value = _allProductsCache.fold(
          0.0, (acc, p) => acc + p.totalPrice,
        );
      } else {
        // Cache all products (one-time), then compute total
        await _ensureAllProductsCached();
      }
    } catch (e) {
      debugPrint('Error fetching overall total: $e');
    } finally {
      isCalculatingTotal.value = false;
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
      _allProductsCache.clear();
      _allProductsFetched = false;
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
        // After first page is loaded and displayed, asynchronously fetch total & warm cache in the background
        fetchOverallTotal();
      }
    }
  }
}
