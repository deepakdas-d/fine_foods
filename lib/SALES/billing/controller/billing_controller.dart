import 'dart:developer';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:fine_foods/ADMIN/Bills/billing_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:fine_foods/home/printer_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class BillingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final customerName = TextEditingController();
  final customerPhone = TextEditingController();
  var customerDiscount = ''.obs;

  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxMap<String, int> selectedProducts = <String, int>{}.obs;
  final RxMap<String, double> customPrices = <String, double>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final controller = Get.put(BillListController());

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

  double getCustomPrice(Product product) {
    return customPrices[product.id] ?? product.price;
  }

  void setCustomPrice(Product product, double price) {
    if (price > 0) {
      customPrices[product.id] = price;
    } else {
      customPrices.remove(product.id);
    }
  }

  void increaseQuantity(Product product) {
    final currentQuantity = selectedProducts[product.id] ?? 0;
    if (product.count > currentQuantity) {
      selectedProducts[product.id] = currentQuantity + 1;
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
        customPrices.remove(product.id);
        _showFeedback('${product.name} removed from cart');
      } else {
        selectedProducts[product.id] = currentQuantity - 1;
      }
    }
  }

  void clearCart() {
    selectedProducts.clear();
    customPrices.clear();
    customerName.clear();
    customerPhone.clear();
  }

  double calculateTotal() {
    double total = 0;
    for (var product in products) {
      if (selectedProducts.containsKey(product.id)) {
        final price = getCustomPrice(product);
        total += price * selectedProducts[product.id]!;
      }
    }
    final discount = customerDiscount.trim().isEmpty
        ? 0.0
        : double.tryParse(customerDiscount.trim()) ?? 0.0;
    return (total - discount).clamp(0, double.infinity);
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

      final globalDiscount = customerDiscount.trim().isEmpty
          ? 0.0
          : double.tryParse(customerDiscount.trim()) ?? 0.0;

      final billData = {
        'invoiceNumber': invoiceNumber,
        'customerName': customerName.text.isEmpty
            ? 'Walk-in Customer'
            : customerName.text,
        'customerPhone': customerPhone.text.isEmpty ? '' : customerPhone.text,
        'products': selectedProducts.map((key, value) {
          final product = products.firstWhere((p) => p.id == key);
          final price = getCustomPrice(product);
          return MapEntry(key, {
            'productId': key,
            'productName': product.name,
            'quantity': value,
            'price': price,
            'total': price * value,
          });
        }),
        'total': calculateTotal(),
        'discount': globalDiscount,
        'itemCount': selectedProducts.values.fold(0, (sum, qty) => sum + qty),
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'completed',
      };

      batch.set(_firestore.collection('bills').doc(billId), billData);

      for (var entry in selectedProducts.entries) {
        final product = products.firstWhere((p) => p.id == entry.key);
        batch.update(_firestore.collection('products').doc(product.id), {
          'count': product.count - entry.value,
        });

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

      clearCart();
      if (Get.isBottomSheetOpen == true) {
        Navigator.of(Get.overlayContext!, rootNavigator: true).pop();
      }
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
    final createdAt = DateTime.parse(billData['createdAt']);
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);

    // Get PrinterController
    PrinterController printerController;
    try {
      printerController = Get.find<PrinterController>();
    } catch (e) {
       // If not found, try put
       // ideally it should be put in binding
       // assuming it is available or we put it
       // For safety in this specific refactor:
       // printerController = Get.put(PrinterController());
       // But PrinterController is likely put in HomeBinding.
       // We can try find.
       print('PrinterController not found, assumes it is not initialized?');
       return;
    }

    if (!printerController.isConnected.value) {
      print('DEBUG: Printer not connected');
      Get.snackbar('Error', 'Printer not connected');
      return;
    }

    final esc = EscCommand();
    print('DEBUG: Initializing EscCommand and clearing buffer');
    await esc.cleanCommand();

    esc.text(content: '\x1B\x40');
    esc.text(
      content:
          '\x1B\x61\x01'
          '\x1B\x45\x01'
          '\x1D\x21\x00'
          'WRAPPIE\n'
          'CRAFTS & GIFTS\n'
          '\x1B\x45\x00',
    );
    esc.text(content: '\n');
    esc.text(
      content:
          '\x1B\x61\x01'
          'Main Road Alathur\n'
          '7907609118\n'
          '\x1B\x61\x00',
    );

    esc.text(
      content:
          '\x1B\x61\x00'
          '\x1B\x4D\x01'
          'Invoice #${billData['invoiceNumber']}\n'
          'Date: $formattedDate\n'
          '\x1B\x4D\x00',
    );

    esc.text(content: '--------------------------------\n');
    esc.text(
      content:
          '\x1B\x45\x01'
          'Item          Qty Price  Total\n'
          '\x1B\x45\x00',
    );
    esc.text(content: '--------------------------------\n');

    for (var product in billData['products'].values) {
      String name = product['productName'].toString();
      if (name.length > 13) name = name.substring(0, 13);
      name = name.padRight(13);

      String qty = product['quantity'].toString().padLeft(3);
      String price = product['price'].toStringAsFixed(2).padLeft(6);
      String total = product['total'].toStringAsFixed(2).padLeft(6);

      esc.text(content: '$name $qty $price $total\n');
    }

    esc.text(content: '--------------------------------\n');

    final subtotal = controller.calculateBillSubtotal(billData);
    final discount = controller.calculateBillDiscount(billData);
    final finalTotal = (subtotal - discount).clamp(0, double.infinity);

    esc.text(
      content:
          '\x1B\x61\x02'
          'Subtotal: Rs${subtotal.toStringAsFixed(2)}\n',
    );
    if (discount > 0) {
      esc.text(
        content:
            '\x1B\x61\x02'
            'Discount: Rs${discount.toStringAsFixed(2)}\n',
      );
    }
    esc.text(
      content:
          '\x1B\x61\x02'
          '\x1B\x45\x01Total: Rs${finalTotal.toStringAsFixed(2)}\n\x1B\x45\x00',
    );

    esc.text(content: '\n\n\n');

    final cmd = await esc.getCommand();
    if (cmd != null) {
      print('DEBUG: Sending print command (${cmd.length} bytes)');
      await printerController.print(cmd);
      print('DEBUG: Print command sent successfully');
    } else {
      print('DEBUG: Failed to generate command bytes');
    }
  }

  void _showFeedback(String message) {
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
