import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/ADMIN/invoice_generator/invoice_models.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:fine_foods/ADMIN/invoice_view/view/invoice_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class InvoiceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxDouble totalAmount = 0.0.obs;
  final RxString selectedCollection = 'inventory'.obs; // Default to inventory

  var _lastSnackTime = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  void loadProducts() async {
    try {
      isLoading.value = true;
      final querySnapshot = await _firestore
          .collection(selectedCollection.value)
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

  void generateInvoice(String collection) async {
    if (products.isEmpty) {
      Get.snackbar(
        'Error',
        'No products to generate invoice',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      final invoice = Invoice(
        id: _uuid.v4(),
        products: products.toList(),
        createdAt: DateTime.now(),
        totalAmount: totalAmount.value,
      );

      // Save invoice to Firebase
      await _firestore
          .collection('invoices')
          .doc(invoice.id)
          .set(invoice.toMap());

      Get.snackbar(
        'Success',
        'Invoice generated successfully from $collection',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.to(() => InvoiceViewPage(invoice: invoice));
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate invoice: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void calculateTotal() {
    totalAmount.value = products.fold(
      0.0,
      (sumValue, product) => sumValue + product.totalPrice,
    );
  }

  void clearAllProducts() async {
    try {
      isLoading.value = true;

      // Delete all products from the selected collection
      final batch = _firestore.batch();
      for (var product in products) {
        batch.delete(
          _firestore.collection(selectedCollection.value).doc(product.id),
        );
      }
      await batch.commit();

      products.clear();
      calculateTotal();

      showSuccessSnackbar();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to clear products: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void showSuccessSnackbar() {
    final now = DateTime.now();
    if (now.difference(_lastSnackTime).inMilliseconds < 1500) return;

    _lastSnackTime = now;
    Get.snackbar(
      'Success',
      'All products cleared',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}
