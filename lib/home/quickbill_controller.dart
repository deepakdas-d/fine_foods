import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'dart:developer' as developer;

class QuickbillController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  var isLoading = false.obs;
  var customerName = ''.obs;
  var customerPhone = ''.obs;
  var customerDiscount = ''.obs;
  var newProducts = <Map<String, dynamic>>[].obs;

  final productNameController = TextEditingController();
  final productPriceController = TextEditingController();
  final productQuantityController = TextEditingController();
  final productTypeController = TextEditingController(text: 'unit');

  @override
  void onClose() {
    productNameController.dispose();
    productPriceController.dispose();
    productQuantityController.dispose();
    productTypeController.dispose();
    super.onClose();
  }

  void addProduct({
    required String name,
    required double price,
    required double quantity,
    required String type,
  }) {
    final product = {
      'id': const Uuid().v4(),
      'name': name.trim(),
      'price': price,
      'quantity': quantity,
      'type': type,
      'total': price * quantity,
    };
    newProducts.add(product);
    clearProductInputs();
    Get.snackbar(
      'Success',
      'Product added to cart',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void clearProductInputs() {
    productNameController.clear();
    productPriceController.clear();
    productQuantityController.clear();
    productTypeController.text = 'unit';
  }

  void removeProduct(String id) {
    newProducts.removeWhere((product) => product['id'] == id);
  }

  double calculateTotal() {
    double total = 0;
    for (var product in newProducts) {
      total += product['total'] as double;
    }
    final discount = customerDiscount.value.trim().isEmpty
        ? 0.0
        : double.parse(customerDiscount.value.trim());
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
    if (newProducts.isEmpty) {
      Get.snackbar(
        'Error',
        'Please add at least one product',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }

    if (customerPhone.value.trim().isNotEmpty &&
        !RegExp(r'^\d{10}$').hasMatch(customerPhone.value.trim())) {
      Get.snackbar(
        'Error',
        'Enter a valid 10-digit phone number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }

    if (customerDiscount.value.trim().isNotEmpty &&
        (double.tryParse(customerDiscount.value.trim()) == null ||
            double.parse(customerDiscount.value.trim()) <= 0)) {
      Get.snackbar(
        'Error',
        'Enter a valid discount greater than 0',
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

      final globalDiscount = customerDiscount.value.trim().isEmpty
          ? 0.0
          : double.parse(customerDiscount.value.trim());

      final billData = {
        'invoiceNumber': invoiceNumber,
        'customerName': customerName.value.isEmpty
            ? 'Walk-in Customer'
            : customerName.value.trim(),
        'customerPhone': customerPhone.value.trim(),
        'products': newProducts
            .map(
              (product) => {
                'productId': product['id'],
                'productName': product['name'],
                'quantity': product['quantity'],
                'price': product['price'],
                'total': product['total'],
                'type': product['type'],
              },
            )
            .toList(),
        'total': calculateTotal(),
        'discount': globalDiscount,
        'itemCount': newProducts.fold(
          0.0,
          (sum, product) => sum + (product['quantity'] as double),
        ),
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'completed',
      };

      batch.set(_firestore.collection('bills').doc(billId), billData);
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

  void clearCart() {
    newProducts.clear();
    customerName.value = '';
    customerPhone.value = '';
    customerDiscount.value = '';
    clearProductInputs();
  }

  double calculateBillSubtotal(Map<String, dynamic> billData) {
    double subtotal = 0;
    for (var product in billData['products']) {
      subtotal += product['total'] as double;
    }
    return subtotal;
  }

  double calculateBillDiscount(Map<String, dynamic> billData) {
    return billData['discount'] as double? ?? 0.0;
  }

  Future<void> printInvoice(Map<String, dynamic> billData) async {
    try {
      if (!BluetoothPrintPlus.isConnected) {
        throw Exception('Printer not connected');
      }

      final createdAt = DateTime.parse(billData['createdAt']);
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);

      final esc = EscCommand();
      await esc.cleanCommand();

      esc.text(content: '\x1B\x40');
      esc.text(
        content:
            '\x1B\x61\x01\x1B\x45\x01\x1D\x21\x00WRAPPIE\nCRAFTS & GIFTS\n\x1B\x45\x00',
      );
      esc.text(content: '\n');
      esc.text(
        content: '\x1B\x61\x01Main Road Alathur\n7907609118\n\x1B\x61\x00',
      );

      esc.text(
        content:
            '\x1B\x61\x00\x1B\x4D\x01Invoice #${billData['invoiceNumber']}\nDate: $formattedDate\nCustomer: ${billData['customerName']}\n${billData['customerPhone'].isNotEmpty ? 'Phone: ${billData['customerPhone']}\n' : ''}\x1B\x4D\x00',
      );

      esc.text(content: '--------------------------------\n');
      esc.text(
        content: '\x1B\x45\x01Item          Qty  Price  Total\n\x1B\x45\x00',
      );
      esc.text(content: '--------------------------------\n');

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

      final subtotal = calculateBillSubtotal(billData);
      final discount = calculateBillDiscount(billData);
      final finalTotal = (subtotal - discount).clamp(0, double.infinity);

      esc.text(
        content: '\x1B\x61\x02Subtotal: Rs${subtotal.toStringAsFixed(2)}\n',
      );
      if (discount > 0) {
        esc.text(
          content: '\x1B\x61\x02Discount: Rs${discount.toStringAsFixed(2)}\n',
        );
      }
      esc.text(
        content:
            '\x1B\x61\x02\x1B\x45\x01Total: Rs${finalTotal.toStringAsFixed(2)}\n\x1B\x45\x00',
      );

      esc.text(content: '\n\n\n');

      final cmd = await esc.getCommand();
      if (cmd == null) {
        throw Exception('Failed to generate print command');
      }

      await BluetoothPrintPlus.write(cmd);
      Get.snackbar(
        'Success',
        'Invoice printed successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to print invoice: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
