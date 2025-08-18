import 'dart:developer';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
import 'package:get/get.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
// import 'package:flutter/services.dart';
// import 'package:printing/printing.dart';
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
            'discount': customerDiscount.text.isEmpty
                ? 0
                : double.tryParse(customerDiscount.text),
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

    // Title (center-aligned, bold)
    print('DEBUG: Printing title');
    esc.text(
      content:
          '\x1B\x61\x01\x1B\x45\x01Invoice #${billData['invoiceNumber']}\n\x1B\x45\x00',
    );

    // Customer details (left-aligned)
    print('DEBUG: Printing customer details');
    esc.text(content: '\x1B\x61\x00Customer: ${billData['customerName']}\n');

    if ((billData['customerPhone'] ?? '').toString().isNotEmpty) {
      print('DEBUG: Printing customer phone');
      esc.text(content: 'Phone: ${billData['customerPhone']}\n');
    }

    // Divider
    print('DEBUG: Printing divider');
    esc.text(content: '--------------------------------\n');

    // Products header (bold)
    print('DEBUG: Printing products header');
    esc.text(content: '\x1B\x45\x01Products:\n\x1B\x45\x00');
    esc.text(content: 'Product        Qty   Price   Total\n');

    // Products
    print('DEBUG: Printing products list');
    for (var product in billData['products'].values) {
      print('DEBUG: Printing product: ${product['productName']}');
      esc.text(
        content:
            '${product['productName']}  ${product['quantity']}   \$${product['price']}   \$${product['total']}\n',
      );
    }

    // Totals
    print('DEBUG: Printing totals section');
    esc.text(content: '--------------------------------\n');
    esc.text(
      content: '\x1B\x45\x01Total: \$${billData['total']}\n\x1B\x45\x00',
    );
    esc.text(content: 'Items: ${billData['itemCount']}\n');
    esc.text(content: 'Date: ${billData['createdAt']}\n\n\n\n');

    // Print
    print('DEBUG: Generating command bytes');
    final cmd = await esc.getCommand();
    if (cmd != null) {
      print('DEBUG: Command bytes generated: ${cmd.length} bytes');
      print('DEBUG: Sending to printer');
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
