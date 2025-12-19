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

  /// Printing remains the same (no payment info)
  Future<void> printInvoice(Map<String, dynamic> billData) async {
    developer.log(
      '[QuickbillController] Starting printInvoice for invoice #${billData['invoiceNumber']}',
    );
    try {
      final PrinterController printerController = Get.find<PrinterController>();
      developer.log(
        '[QuickbillController] PrinterController found. Is connected: ${printerController.isConnected.value}',
      );
      if (!printerController.isConnected.value) {
        throw Exception('Printer not connected');
      }

      final createdAt = DateTime.parse(billData['createdAt']);
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);

      Uint8List printBytes; // Non-final, assigned in both branches

      if (GetPlatform.isWindows || kIsWeb) {
        developer.log(
          '[QuickbillController] Generating ESC/POS bytes for Windows using flutter_esc_pos_utils',
        );

        final profile = await CapabilityProfile.load();
        final generator = Generator(
          PaperSize.mm80,
          profile,
        ); // Change to mm58 if needed

        List<int> bytesList = []; // ← Removed 'final' — now mutable

        // Initialize printer
        bytesList += generator.reset();
        bytesList += generator.text('\x1B\x40'); // ESC @

        // Header - Large centered bold
        bytesList += generator.text(
          'WRAPPIE CRAFTS & GIFTS',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        );
        bytesList += generator.text(
          'Main Road Alathur, 7907609118',
          styles: const PosStyles(align: PosAlign.center),
        );

        bytesList += generator.emptyLines(1);

        // Invoice info
        bytesList += generator.text(
          'Invoice #${billData['invoiceNumber']}',
          styles: const PosStyles(bold: true),
        );
        bytesList += generator.text('Date: $formattedDate');
        bytesList += generator.text('Customer: ${billData['customerName']}');
        if (billData['customerPhone'].isNotEmpty) {
          bytesList += generator.text('Phone: ${billData['customerPhone']}');
        }

        bytesList += generator.hr(ch: '-');

        // Table header
        bytesList += generator.row([
          PosColumn(
            text: 'Item',
            width: 6,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            text: 'Qty',
            width: 2,
            styles: const PosStyles(bold: true, align: PosAlign.center),
          ),
          PosColumn(
            text: 'Price',
            width: 2,
            styles: const PosStyles(bold: true, align: PosAlign.right),
          ),
          PosColumn(
            text: 'Total',
            width: 2,
            styles: const PosStyles(bold: true, align: PosAlign.right),
          ),
        ]);
        bytesList += generator.hr(ch: '-');

        // Product rows
        for (var product in billData['products']) {
          String name = product['productName'].toString();
          if (name.length > 18) name = name.substring(0, 18);

          bytesList += generator.row([
            PosColumn(text: name, width: 6),
            PosColumn(
              text: product['quantity'].toString(),
              width: 2,
              styles: const PosStyles(align: PosAlign.center),
            ),
            PosColumn(
              text: 'Rs${product['price'].toStringAsFixed(2)}',
              width: 2,
              styles: const PosStyles(align: PosAlign.right),
            ),
            PosColumn(
              text: 'Rs${product['total'].toStringAsFixed(2)}',
              width: 2,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]);
        }

        bytesList += generator.hr(ch: '-');

        // Totals
        final subtotal = calculateBillSubtotal(billData);
        final discount = calculateBillDiscount(billData);
        final finalTotal = (subtotal - discount).clamp(0, double.infinity);

        bytesList += generator.text(
          'Subtotal: Rs${subtotal.toStringAsFixed(2)}',
          styles: const PosStyles(align: PosAlign.right),
        );
        if (discount > 0) {
          bytesList += generator.text(
            'Discount: Rs${discount.toStringAsFixed(2)}',
            styles: const PosStyles(align: PosAlign.right),
          );
        }
        bytesList += generator.text(
          'Total: Rs${finalTotal.toStringAsFixed(2)}',
          styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        );

        bytesList += generator.feed(3);
        bytesList += generator.cut();

        developer.log(
          '[QuickbillController] Generated ${bytesList.length} bytes for Windows',
        );

        printBytes = Uint8List.fromList(bytesList);
      } else {
        // Android: Keep using bluetooth_print_plus
        developer.log(
          '[QuickbillController] Generating ESC/POS bytes for Android using bluetooth_print_plus',
        );

        final esc = EscCommand();
        await esc.cleanCommand();
        esc.text(content: '\x1B\x40');

        // Your original manual ESC/POS formatting
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
        if (cmd == null) throw Exception('Failed to generate print command');

        printBytes = Uint8List.fromList(cmd);
        developer.log(
          '[QuickbillController] Generated ${cmd.length} bytes for Android',
        );
      }

      // Common: Send to printer
      developer.log(
        '[QuickbillController] Sending ${printBytes.length} bytes to printer',
      );
      await printerController.print(printBytes);
      developer.log('[QuickbillController] Print job sent successfully');

      Get.snackbar(
        'Success',
        'Invoice printed successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      developer.log(
        '[QuickbillController] PrintInvoice failed: $e',
        level: 1000,
      );
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
