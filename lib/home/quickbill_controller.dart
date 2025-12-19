import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:fine_foods/home/printer_controller.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart' show GetPlatform;
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

class QuickbillController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  var isLoading = false.obs;
  var customerName = ''.obs;
  var customerPhone = ''.obs;
  var customerDiscount = ''.obs;
  var paymentMethod = 'Cash'.obs; // cash / card / upi
  var paidAmount = ''.obs;
  var paymentStatus = 'paid'.obs; // paid / pending
  var newProducts = <Map<String, dynamic>>[].obs;
  var selectedPaymentType = 'Full'.obs; // Full / Split
  var cashReceived = ''.obs;
  var onlineReceived = ''.obs;

  final productNameController = TextEditingController();
  final productPriceController = TextEditingController();
  final productQuantityController = TextEditingController();
  final selectedType = 'unit'.obs;

  @override
  void onClose() {
    productNameController.dispose();
    productPriceController.dispose();
    productQuantityController.dispose();
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
    selectedType.value = 'unit';
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

  //////------------------------------------------------Create Bill Function------------------------------------------------//////
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

      final totalAmount = calculateTotal();
      final discount = customerDiscount.value.trim().isEmpty
          ? 0.0
          : double.parse(customerDiscount.value.trim());

      /// 🔴 EDGE CASE: TOTAL MUST BE > 0
      if (totalAmount <= 0) {
        Get.snackbar(
          'Error',
          'Total amount must be greater than 0',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }

      double cash = 0;
      double online = 0;

      /// ✅ FULL PAYMENT (Cash OR Online)
      if (selectedPaymentType.value == 'Full') {
        if (paymentMethod.value == 'Cash') {
          cash = totalAmount;
          online = 0;
        } else if (paymentMethod.value == 'Online') {
          cash = 0;
          online = totalAmount;
        }
      }

      /// ✅ SPLIT PAYMENT (Cash + Online)
      if (selectedPaymentType.value == 'Split') {
        cash = double.tryParse(cashReceived.value) ?? 0;
        online = double.tryParse(onlineReceived.value) ?? 0;

        if ((cash + online) != totalAmount) {
          Get.snackbar(
            'Error',
            'Cash + Online must equal total amount',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return null;
        }
      }

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

        'subtotal': newProducts.fold(
          0.0,
          (sum, p) => sum + (p['total'] as double),
        ),

        'discount': discount,
        'total': totalAmount,
        'itemCount': newProducts.fold(
          0.0,
          (sum, p) => sum + (p['quantity'] as double),
        ),

        /// 💳 PAYMENT INFO
        'paymentType': selectedPaymentType.value, // Full / Split
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
        'Failed to create invoice',
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
    paidAmount.value = '';
    paymentMethod.value = 'cash';
    paymentStatus.value = 'paid';
    onlineReceived.value = '';
    cashReceived.value = '';
    selectedPaymentType.value = 'Full';
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
    developer.log(
      '[QuickbillController] Starting printInvoice for invoice #${billData['invoiceNumber']}',
    );

    try {
      final PrinterController printerController = Get.find<PrinterController>();

      if (!printerController.isConnected.value) {
        throw Exception('Printer not connected');
      }

      final createdAt = DateTime.parse(billData['createdAt']);
      final formattedDate = DateFormat('yyyy-MM-dd').format(createdAt);

      Uint8List printBytes;

      // ================= WINDOWS / WEB =================
      if (GetPlatform.isWindows || kIsWeb) {
        developer.log('[QuickbillController] Windows ESC/POS (pixel-stable)');

        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);

        List<int> bytes = [];
        bytes += generator.reset();

        // -------- STYLES --------
        const centerBold = PosStyles(
          align: PosAlign.center,
          bold: true,
          fontType: PosFontType.fontA,
        );

        const center = PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontA,
        );

        const normal = PosStyles(fontType: PosFontType.fontA);

        const bold = PosStyles(bold: true, fontType: PosFontType.fontA);

        // -------- HEADER (NO size2 = NO pixel jump) --------
        bytes += generator.text('WRAPPIE', styles: centerBold);
        bytes += generator.text('CRAFTS & GIFTS', styles: centerBold);
        bytes += generator.text('Main Road Alathur', styles: center);
        bytes += generator.text('7907609118', styles: center);
        bytes += generator.feed(1);

        // -------- INVOICE INFO --------
        bytes += generator.text(
          'Invoice #${billData['invoiceNumber']}',
          styles: normal,
        );

        bytes += generator.text('Date: $formattedDate', styles: normal);

        if (billData['customerPhone'].isNotEmpty) {
          bytes += generator.text(
            'Phone: ${billData['customerPhone']}',
            styles: normal,
          );
        }

        // -------- TABLE HEADER (TEXT BASED) --------
        bytes += generator.text('--------------------------------');
        bytes += generator.text(
          'Item          Qty  Price  Total',
          styles: bold,
        );
        bytes += generator.text('--------------------------------');

        // -------- PRODUCTS (MONOSPACE SAFE) --------
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

        // -------- TOTALS (NO size2) --------
        final subtotal = calculateBillSubtotal(billData);
        final discount = calculateBillDiscount(billData);
        final finalTotal = (subtotal - discount).clamp(0, double.infinity);

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
          'Total:    Rs${finalTotal.toStringAsFixed(2).padLeft(8)}',
          styles: bold,
        );

        bytes += generator.feed(1);
        bytes += generator.cut();

        printBytes = Uint8List.fromList(bytes);
      }
      // ================= ANDROID =================
      else {
        developer.log('[QuickbillController] Android ESC/POS');

        final esc = EscCommand();
        await esc.cleanCommand();
        esc.text(content: '\x1B\x40');

        esc.text(
          content:
              '\x1B\x61\x01\x1B\x45\x01WRAPPIE\nCRAFTS & GIFTS\n\x1B\x45\x00',
        );
        esc.text(content: '\n');
        esc.text(
          content: '\x1B\x61\x01Main Road Alathur\n7907609118\n\x1B\x61\x00',
        );

        esc.text(
          content:
              'Invoice #${billData['invoiceNumber']}\nDate: $formattedDate\n'
              '${billData['customerPhone'].isNotEmpty ? 'Phone: ${billData['customerPhone']}\n' : ''}',
        );

        esc.text(content: '--------------------------------\n');
        esc.text(content: 'Item          Qty  Price  Total\n');
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

        esc.text(content: 'Subtotal: Rs${subtotal.toStringAsFixed(2)}\n');

        if (discount > 0) {
          esc.text(content: 'Discount: Rs${discount.toStringAsFixed(2)}\n');
        }

        esc.text(
          content:
              '\x1B\x45\x01Total: Rs${finalTotal.toStringAsFixed(2)}\n\x1B\x45\x00',
        );

        esc.text(content: '\n\n\n');

        final cmd = await esc.getCommand();
        if (cmd == null) throw Exception('Failed to generate print command');

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
      developer.log('[QuickbillController] Print failed: $e', level: 1000);

      Get.snackbar(
        'Error',
        'Failed to print invoice',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
