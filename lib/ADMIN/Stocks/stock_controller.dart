import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StockAvailabilityController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final products = <Product>[].obs;
  final isLoading = false.obs;
  final total = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  void calculateTotal() {
    total.value = products.fold(0, (sum, product) => sum + product.totalPrice);
  }

  void loadProducts() async {
    try {
      isLoading.value = true;

      final querySnapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      products.clear();
      for (var doc in querySnapshot.docs) {
        final product = Product.fromMap(doc.data());
        products.add(product);
      }

      calculateTotal();
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
