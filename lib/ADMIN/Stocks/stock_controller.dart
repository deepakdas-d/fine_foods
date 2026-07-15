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
    calculateTotal();
  }

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  void calculateTotal() {
    total.value = products.fold(0, (sumValue, product) => sumValue + product.totalPrice);
  }

  void loadProducts() async {
    try {
      isLoading.value = true;

      final querySnapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      allProducts.clear();
      for (var doc in querySnapshot.docs) {
        final product = Product.fromMap(doc.data());
        allProducts.add(product);
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
      isLoading.value = false;
    }
  }
}
