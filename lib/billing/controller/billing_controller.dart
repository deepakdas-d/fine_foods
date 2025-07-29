import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/invoice_generator/models/product_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class BillingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final customerName = TextEditingController();
  final customerPhone = TextEditingController();
  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxMap<String, int> selectedProducts = <String, int>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    filteredProducts.assignAll(products);
  }

  void fetchProducts() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore.collection('products').get();
      products.value = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();

      // Sort products by name for better UX
      products.sort((a, b) => a.name.compareTo(b.name));

      searchProducts(searchQuery.value);
    } catch (e) {
      log('Failed to fetch products: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch products: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void searchProducts(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredProducts.assignAll(products);
    } else {
      filteredProducts.assignAll(
        products
            .where(
              (product) =>
                  product.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList(),
      );
    }
  }

  int getSelectedQuantity(Product product) {
    return selectedProducts[product.id] ?? 0;
  }

  void increaseQuantity(Product product) {
    final currentQuantity = selectedProducts[product.id] ?? 0;
    if (product.count > currentQuantity) {
      selectedProducts[product.id] = currentQuantity + 1;
      _showFeedback('${product.name} added to cart');
    } else {
      Get.snackbar(
        'Out of Stock',
        '${product.name} is out of stock',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void decreaseQuantity(Product product) {
    final currentQuantity = selectedProducts[product.id] ?? 0;
    if (currentQuantity > 0) {
      if (currentQuantity == 1) {
        selectedProducts.remove(product.id);
        _showFeedback('${product.name} removed from cart');
      } else {
        selectedProducts[product.id] = currentQuantity - 1;
        _showFeedback('${product.name} quantity decreased');
      }
    }
  }

  void clearCart() {
    selectedProducts.clear();
    customerName.clear();
    customerPhone.clear();
    _showFeedback('Cart cleared');
  }

  double calculateTotal() {
    double total = 0;
    for (var product in products) {
      if (selectedProducts.containsKey(product.id)) {
        total += product.price * selectedProducts[product.id]!;
      }
    }
    return total;
  }

  String generateInvoiceNumber() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd');
    final dateString = formatter.format(now);
    final timeString = DateFormat('HHmmss').format(now);
    return 'INV-$dateString-$timeString';
  }

  void createBill() async {
    if (selectedProducts.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one product',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final billId = const Uuid().v4();
      final invoiceNumber = generateInvoiceNumber();
      final batch = _firestore.batch();

      // Create bill document with optional customer details
      final billData = {
        'invoiceNumber': invoiceNumber,
        'customerName': customerName.text.isEmpty
            ? 'Walk-in Customer'
            : customerName.text,
        'customerPhone': customerPhone.text.isEmpty ? '' : customerPhone.text,
        'products': selectedProducts.map((key, value) {
          final product = products.firstWhere((p) => p.id == key);
          return MapEntry(key, {
            'productId': key,
            'productName': product.name,
            'quantity': value,
            'price': product.price,
            'total': product.price * value,
          });
        }),
        'total': calculateTotal(),
        'itemCount': selectedProducts.values.fold(0, (sum, qty) => sum + qty),
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'completed',
      };

      batch.set(_firestore.collection('bills').doc(billId), billData);

      // Update product counts
      for (var entry in selectedProducts.entries) {
        final product = products.firstWhere((p) => p.id == entry.key);
        batch.update(_firestore.collection('products').doc(product.id), {
          'count': product.count - entry.value,
        });

        // Update local product list
        final index = products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          products[index] = Product(
            id: product.id,
            name: product.name,
            count: product.count - entry.value,
            price: product.price,
            createdAt: product.createdAt,
          );
        }
      }

      await batch.commit();

      Get.snackbar(
        'Success',
        'Invoice $invoiceNumber created successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Clear the cart and customer details
      clearCart();
      filteredProducts.assignAll(products);
    } catch (e) {
      log('Failed to create bill: $e');
      Get.snackbar(
        'Error',
        'Failed to create invoice: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showFeedback(String message) {
    Get.showSnackbar(
      GetSnackBar(
        message: message,
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.black87,
        borderRadius: 8,
        margin: const EdgeInsets.all(16),
        snackStyle: SnackStyle.FLOATING,
      ),
    );
  }

  @override
  void onClose() {
    customerName.dispose();
    customerPhone.dispose();
    super.onClose();
  }
}
