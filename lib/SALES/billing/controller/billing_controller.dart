import 'dart:developer';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:fine_foods/ADMIN/Bills/billing_list_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:fine_foods/home/printer_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'dart:typed_data';

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
  RxString selectedPaymentType = 'Full'.obs;
  RxString paymentMethod = 'Cash'.obs;
  RxString cashReceived = ''.obs;
  RxString onlineReceived = ''.obs;
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
      Get.snackbar('Error', 'Please select at least one product');
      return null;
    }

    // Phone validation (optional but if filled → 10 digits)
    if (customerPhone.text.trim().isNotEmpty &&
        !RegExp(r'^\d{10}$').hasMatch(customerPhone.text.trim())) {
      Get.snackbar('Error', 'Enter a valid 10-digit phone number');
      return null;
    }

    // Discount validation
    if (customerDiscount.value.trim().isNotEmpty) {
      final disc = double.tryParse(customerDiscount.value.trim());
      if (disc == null || disc <= 0) {
        Get.snackbar('Error', 'Enter a valid discount greater than 0');
        return null;
      }
      if (disc > calculateTotal()) {
        Get.snackbar('Error', 'Discount cannot exceed total amount');
        return null;
      }
    }

    isLoading.value = true;

    try {
      final billId = const Uuid().v4();
      final invoiceNumber = generateInvoiceNumber();
      final batch = _firestore.batch();

      final totalAmount = calculateTotal();
      final discount = customerDiscount.value.trim().isEmpty
          ? 0.0
          : double.parse(customerDiscount.value.trim());

      if (totalAmount <= 0) {
        Get.snackbar('Error', 'Total amount must be greater than 0');
        return null;
      }

      double cash = 0;
      double online = 0;

      // Determine payment amounts
      if (selectedPaymentType.value == 'Full') {
        if (paymentMethod.value == 'Cash') {
          cash = totalAmount;
        } else if (paymentMethod.value == 'Online') {
          online = totalAmount;
        }
      } else if (selectedPaymentType.value == 'Split') {
        cash = double.tryParse(cashReceived.value) ?? 0;
        online = double.tryParse(onlineReceived.value) ?? 0;

        if ((cash + online) != totalAmount) {
          Get.snackbar('Error', 'Cash + Online must equal total amount');
          return null;
        }
      }

      final billData = {
        'invoiceNumber': invoiceNumber,
        'customerName': customerName.text.isEmpty
            ? 'Walk-in Customer'
            : customerName.text.trim(),
        'customerPhone': customerPhone.text.trim(),

        // ✅ FIXED PRODUCTS LIST
        'products': selectedProducts.entries.map((entry) {
          final product = products.firstWhere((p) => p.id == entry.key);
          final price = getCustomPrice(product);

          return {
            'productId': product.id,
            'productName': product.name,
            'quantity': entry.value,
            'price': price,
            'total': price * entry.value,
          };
        }).toList(),

        'subtotal': totalAmount + discount,
        'discount': discount,
        'total': totalAmount,

        'itemCount': selectedProducts.values.fold(0, (a, b) => a + b),

        'paymentType': selectedPaymentType.value,
        'paymentMethod': selectedPaymentType.value == 'Split'
            ? 'Both'
            : paymentMethod.value,
        'cashReceived': cash,
        'onlineReceived': online,
        'totalPaid': cash + online,
        'paymentStatus': 'paid',

        'createdAt': DateTime.now().toIso8601String(),
        'status': 'completed',
      };

      // Save bill
      batch.set(_firestore.collection('bills').doc(billId), billData);

      // Update stock
      for (var entry in selectedProducts.entries) {
        final product = products.firstWhere((p) => p.id == entry.key);
        batch.update(_firestore.collection('products').doc(product.id), {
          'count': FieldValue.increment(-entry.value),
        });

        final index = products.indexOf(product);
        if (index != -1) {
          products[index] = product.copyWith(
            count: product.count - entry.value,
          );
        }
      }

      await batch.commit();

      Get.snackbar(
        'Success',
        'Invoice $invoiceNumber created successfully!',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      );

      clearCart();
      filteredProducts.assignAll(products);
      if (Get.isBottomSheetOpen == true) {
        Navigator.of(Get.overlayContext!, rootNavigator: true).pop();
      }

      return billData;
    } catch (e) {
      developer.log('Failed to create bill: $e');
      Get.snackbar('Error', 'Failed to create invoice: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> printInvoice(Map<String, dynamic> billData) async {
    developer.log(
      '[BillingController] Starting printInvoice for invoice #${billData['invoiceNumber']}',
    );

    try {
      final PrinterController printerController = Get.find<PrinterController>();

      if (!printerController.isConnected.value) {
        throw Exception('Printer not connected');
      }

      final createdAt = DateTime.parse(billData['createdAt']);
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);

      Uint8List printBytes;

      // ================= WINDOWS / WEB =================
      if (GetPlatform.isWindows || kIsWeb) {
        developer.log(
          '[BillingController] Using Generator (Windows/Web stable)',
        );

        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);

        List<int> bytes = [];
        bytes += generator.reset();

        // Styles
        const centerBold = PosStyles(
          align: PosAlign.center,
          bold: true,
          fontType: PosFontType.fontA,
        );
        const center = PosStyles(align: PosAlign.center);
        const normal = PosStyles();
        const bold = PosStyles(bold: true);

        // Header
        bytes += generator.text('WRAPPIE', styles: centerBold);
        bytes += generator.text('CRAFTS & GIFTS', styles: centerBold);
        bytes += generator.text('Main Road Alathur', styles: center);
        bytes += generator.text('7907609118', styles: center);
        bytes += generator.feed(1);

        // Invoice Info
        bytes += generator.text(
          'Invoice #${billData['invoiceNumber']}',
          styles: normal,
        );
        bytes += generator.text('Date: $formattedDate', styles: normal);

        if ((billData['customerPhone'] ?? '').toString().trim().isNotEmpty) {
          bytes += generator.text(
            'Phone: ${billData['customerPhone']}',
            styles: normal,
          );
        }

        // Table Header
        bytes += generator.text('--------------------------------');
        bytes += generator.text('Item         Qty Price  Total', styles: bold);
        bytes += generator.text('--------------------------------');

        // Products
        for (var product in billData['products']) {
          String name = product['productName'].toString();
          if (name.length > 12) name = name.substring(0, 12);
          name = name.padRight(12);

          String qty = product['quantity'].toString().padLeft(3);
          String price = product['price'].toStringAsFixed(2).padLeft(7);
          String total = product['total'].toStringAsFixed(2).padLeft(7);

          bytes += generator.text('$name $qty $price $total', styles: normal);
        }

        bytes += generator.text('--------------------------------');

        // Totals
        final subtotal =
            billData['subtotal'] ??
            (billData['total'] + (billData['discount'] ?? 0));
        final discount = billData['discount'] ?? 0;
        final total = billData['total'];

        bytes += generator.text(
          'Subtotal: Rs${subtotal.toStringAsFixed(2).padLeft(8)}',
          styles: normal,
        );
        if (discount > 0) {
          bytes += generator.text(
            'Discount: Rs${discount.toStringAsFixed(2).padLeft(8)}',
            styles: normal,
          );
        }
        bytes += generator.text(
          'Total:    Rs${total.toStringAsFixed(2).padLeft(8)}',
          styles: bold,
        );

        // Payment Details
        final paymentType = billData['paymentType'] ?? 'Full';
        final paymentMethod = billData['paymentMethod'] ?? 'Cash';
        final cash = (billData['cashReceived'] ?? 0).toDouble();
        final online = (billData['onlineReceived'] ?? 0).toDouble();

        bytes += generator.feed(1);
        bytes += generator.text(
          'Payment: $paymentMethod (${paymentType == 'Split' ? 'Split' : 'Full'})',
          styles: normal,
        );
        if (cash > 0) {
          bytes += generator.text(
            'Cash Received: Rs${cash.toStringAsFixed(2)}',
            styles: normal,
          );
        }
        if (online > 0) {
          bytes += generator.text(
            'Online Received: Rs${online.toStringAsFixed(2)}',
            styles: normal,
          );
        }
        bytes += generator.text(
          'Total Paid: Rs${(cash + online).toStringAsFixed(2)}',
          styles: bold,
        );

        bytes += generator.feed(2);
        bytes += generator.cut();

        printBytes = Uint8List.fromList(bytes);
      }
      // ================= ANDROID =================
      else {
        developer.log('[BillingController] Using raw ESC/POS (Android)');

        final esc = EscCommand();
        await esc.cleanCommand();

        esc.text(content: '\x1B\x40');

        // Header
        esc.text(
          content:
              '\x1B\x61\x01\x1B\x45\x01WRAPPIE\nCRAFTS & GIFTS\n\x1B\x45\x00',
        );
        esc.text(content: '\n');
        esc.text(
          content: '\x1B\x61\x01Main Road Alathur\n7907609118\n\x1B\x61\x00',
        );

        // Invoice Info
        String phoneLine =
            (billData['customerPhone'] ?? '').toString().trim().isNotEmpty
            ? 'Phone: ${billData['customerPhone']}\n'
            : '';

        esc.text(
          content:
              'Invoice #${billData['invoiceNumber']}\nDate: $formattedDate\n$phoneLine',
        );

        esc.text(content: '--------------------------------\n');
        esc.text(
          content: '\x1B\x45\x01Item         Qty Price  Total\n\x1B\x45\x00',
        );
        esc.text(content: '--------------------------------\n');

        // Products
        for (var product in billData['products']) {
          String name = product['productName'].toString();
          if (name.length > 12) name = name.substring(0, 12);
          name = name.padRight(12);

          String qty = product['quantity'].toString().padLeft(3);
          String price = product['price'].toStringAsFixed(2).padLeft(6);
          String total = product['total'].toStringAsFixed(2).padLeft(6);

          esc.text(content: '$name $qty $price $total\n');
        }

        esc.text(content: '--------------------------------\n');

        // Totals
        final subtotal =
            billData['subtotal'] ??
            (billData['total'] + (billData['discount'] ?? 0));
        final discount = billData['discount'] ?? 0;
        final total = billData['total'];

        esc.text(content: 'Subtotal: Rs${subtotal.toStringAsFixed(2)}\n');
        if (discount > 0) {
          esc.text(content: 'Discount: Rs${discount.toStringAsFixed(2)}\n');
        }
        esc.text(
          content:
              '\x1B\x45\x01Total: Rs${total.toStringAsFixed(2)}\n\x1B\x45\x00',
        );

        // Payment Details
        final paymentType = billData['paymentType'] ?? 'Full';
        final paymentMethod = billData['paymentMethod'] ?? 'Cash';
        final cash = (billData['cashReceived'] ?? 0).toDouble();
        final online = (billData['onlineReceived'] ?? 0).toDouble();

        esc.text(content: '\n');
        esc.text(
          content:
              'Payment: $paymentMethod (${paymentType == 'Split' ? 'Split' : 'Full'})\n',
        );
        if (cash > 0) {
          esc.text(content: 'Cash Received: Rs${cash.toStringAsFixed(2)}\n');
        }
        if (online > 0) {
          esc.text(
            content: 'Online Received: Rs${online.toStringAsFixed(2)}\n',
          );
        }
        esc.text(
          content: 'Total Paid: Rs${(cash + online).toStringAsFixed(2)}\n',
        );

        esc.text(content: '\n\n\n');

        final cmd = await esc.getCommand();
        if (cmd == null) throw Exception('Failed to generate ESC command');

        printBytes = Uint8List.fromList(cmd);
      }

      // ================= SEND TO PRINTER =================
      await printerController.print(printBytes);

      Get.snackbar(
        'Success',
        'Invoice printed successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      developer.log('[BillingController] Print failed: $e', level: 1000);

      Get.snackbar(
        'Error',
        'Failed to print invoice: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
