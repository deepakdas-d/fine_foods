import 'dart:developer';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class BillingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final customerName = TextEditingController();
  final customerPhone = TextEditingController();
  final customerDiscount = TextEditingController();

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
      final lowerQuery = query.toLowerCase();
      filteredProducts.assignAll(
        products
            .where(
              (product) =>
                  product.name.toLowerCase().contains(lowerQuery) ||
                  product.productId.toLowerCase().contains(lowerQuery),
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
    customerDiscount.clear();
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

  Future<Map<String, dynamic>?> createBill() async {
    if (selectedProducts.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one product',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }

    isLoading.value = true;
    try {
      final billId = const Uuid().v4();
      final invoiceNumber = generateInvoiceNumber();
      final batch = _firestore.batch();

      // Create bill document with optional customer details
      // Parse the discount once
      final globalDiscount = customerDiscount.text.trim().isEmpty
          ? 0.0
          : double.tryParse(customerDiscount.text.trim()) ?? 0.0;

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
            // Remove discount here
          });
        }),
        'total':
            calculateTotal(), // this should be total **after discount** if needed
        'discount': globalDiscount, // store global discount here
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
            productId: product.productId,
            name: product.name,
            count: product.count - entry.value,
            price: product.price,
            createdAt: product.createdAt,
            quantityType: product.quantityType,
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

      return billData;
    } catch (e) {
      developer.log('Failed to create bill: $e');
      Get.snackbar(
        'Error',
        'Failed to create invoice: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> printInvoice(Map<String, dynamic> billData) async {
    print('DEBUG: Starting printInvoice with billData: $billData');

    if (!BluetoothPrintPlus.isConnected) {
      print('DEBUG: Printer not connected');
      return;
    }

    final esc = EscCommand();
    print('DEBUG: Initializing EscCommand and clearing buffer');
    await esc.cleanCommand();

    // Initialize printer (reset settings)
    esc.text(content: '\x1B\x40');

    // Shop Name - Centered, Bold, Smaller Font
    esc.text(
      content:
          '\x1B\x61\x01' // Center align
          '\x1B\x45\x01' // Bold ON
          '\x1D\x21\x00' // Normal size (58mm printer, 32 chars width)
          'FINE FOODS\n'
          '\x1B\x45\x00', // Bold OFF
    );

    // Invoice Title - Centered, Bold
    esc.text(
      content:
          '\x1B\x61\x01\x1B\x45\x01Invoice #${billData['invoiceNumber']}\n\x1B\x45\x00',
    );

    // Divider (32 characters for 58mm width)
    esc.text(content: '--------------------------------\n');

    // Customer Details - Left-aligned
    esc.text(content: '\x1B\x61\x00Customer: ${billData['customerName']}\n');
    if ((billData['customerPhone'] ?? '').toString().isNotEmpty) {
      esc.text(content: 'Phone: ${billData['customerPhone']}\n');
    }

    // Divider
    esc.text(content: '--------------------------------\n');

    // Products Header - Bold
    esc.text(content: '\x1B\x61\x00\x1B\x45\x01Items:\n\x1B\x45\x00');

    // Table Header (optimized for 32 chars: Item 14, Qty 4, Price 7, Total 7)
    esc.text(content: 'Item          Qty Price  Total\n');

    // Products List
    for (var product in billData['products'].values) {
      String name = product['productName'].toString();
      if (name.length > 13) name = name.substring(0, 13); // Fit 13 chars
      name = name.padRight(13); // Item column (13 chars)

      String qty = product['quantity'].toString().padLeft(
        3,
      ); // Qty column (3 chars)
      String price = product['price'].toString().padLeft(
        6,
      ); // Price column (6 chars)
      String total = product['total'].toString().padLeft(
        6,
      ); // Total column (6 chars)

      esc.text(content: '$name $qty $price $total\n');
    }

    // Divider
    esc.text(content: '--------------------------------\n');

    // Totals Section - Right-aligned
    esc.text(
      content:
          '\x1B\x61\x02' // Right align
          '\x1B\x45\x01Total: Rs${billData['total']}\n\x1B\x45\x00',
    );
    esc.text(content: '\x1B\x61\x02Items: ${billData['itemCount']}\n');
    esc.text(content: '\x1B\x61\x02Date: ${billData['createdAt']}\n');

    // Add extra line feeds for paper cut
    esc.text(content: '\n\n\n');

    // Generate and send command bytes
    final cmd = await esc.getCommand();
    if (cmd != null) {
      print('DEBUG: Sending print command (${cmd.length} bytes)');
      await BluetoothPrintPlus.write(cmd);
      print('DEBUG: Print command sent successfully');
    } else {
      print('DEBUG: Failed to generate command bytes');
    }
  }

  void _showFeedback(String message) {
    // If a snackbar is already open, delay showing the next one
    if (Get.isSnackbarOpen) {
      Future.delayed(const Duration(seconds: 1), () {
        _showSnack(message);
      });
    } else {
      _showSnack(message);
    }
  }

  void _showSnack(String message) {
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
