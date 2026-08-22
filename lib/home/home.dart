// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:fine_foods/bluetooth_list.dart';
import 'package:fine_foods/home/printer_controller.dart';
import 'package:fine_foods/home/quickbill_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fine_foods/appcolor.dart';
import 'package:fine_foods/home/user_bills.dart';
import 'package:fine_foods/widgets/responsive.dart';
import 'dart:developer' as developer;

class Home extends StatelessWidget {
  Home({super.key});

  PrinterController get printerController => Get.find<PrinterController>();
  final QuickbillController quickbillController = Get.put(
    QuickbillController(),
  );

  final RxBool isLoading = false.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.background,
        title: const Text(
          "Quick Bill",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColor.textPrimary,
          ),
        ),
        foregroundColor: AppColor.textPrimary,
        actions: [
          // Mobile Bills shortcut
          if (!Responsive.isDesktop(context))
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'My Bills',
              onPressed: () => Get.to(() => const UserBills()),
            ),

          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) // Hide on Web & Desktop
            Obx(() {
              return Row(
                children: [
                  if (printerController.isConnected.value &&
                      printerController.printerName.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        printerController.printerName.value,
                        style: const TextStyle(color: AppColor.textPrimary),
                      ),
                    ),

                  IconButton(
                    icon: Icon(
                      printerController.isConnected.value
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth,
                      color: printerController.isConnected.value
                          ? AppColor.success
                          : null,
                    ),
                    tooltip: printerController.isConnected.value
                        ? 'Printer Connected'
                        : 'Connect Printer',
                    onPressed: () async {
                      await Get.to(() => const BluetoothList());
                      printerController.refreshConnection();
                    },
                  ),
                ],
              );
            }),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProductInputSection(),
            _buildCartSection(),
            _buildCheckoutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInputSection() => Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Product',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ProductInputForm(controller: quickbillController),
      ],
    ),
  );

  Widget _buildCartSection() => Obx(
    () => quickbillController.newProducts.isNotEmpty
        ? Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cart Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: quickbillController.newProducts.length,
                  itemBuilder: (context, index) {
                    final product = quickbillController.newProducts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(product['name']),
                        subtitle: Text(
                          'Qty: ${product['quantity']} | Type: ${product['type']} | Price: ₹${product['price'].toStringAsFixed(2)} | Total: ₹${product['total'].toStringAsFixed(2)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              quickbillController.removeProduct(product['id']),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        : const SizedBox.shrink(),
  );
  Widget _buildCheckoutSection(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColor.background,
      border: Border(
        top: BorderSide(color: AppColor.textSecondary.withValues(alpha: 0.2)),
      ),
    ),
    child: Column(
      children: [
        // Discount
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: quickbillController.customerDiscountController,
                onChanged: (value) =>
                    quickbillController.customerDiscount.value = value,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Discount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.discount_outlined),
                  isDense: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // discount is optional
                  }

                  final discountVal = double.tryParse(value.trim());
                  if (discountVal == null || discountVal < 0) {
                    return 'Enter a valid discount >= 0';
                  }

                  final currentSubtotal = quickbillController.subtotal;
                  if (quickbillController.discountType.value == 'Percentage' && discountVal > 100) {
                    return 'Cannot exceed 100%';
                  } else if (quickbillController.discountType.value == 'Amount' && discountVal > currentSubtotal) {
                    return 'Cannot exceed subtotal';
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Obx(() => Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: AppColor.textSecondary.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      quickbillController.discountType.value = 'Amount';
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: quickbillController.discountType.value == 'Amount' ? AppColor.primary : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                      ),
                      child: Text('₹', style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: quickbillController.discountType.value == 'Amount' ? Colors.white : AppColor.textPrimary,
                      )),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      quickbillController.discountType.value = 'Percentage';
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: quickbillController.discountType.value == 'Percentage' ? AppColor.primary : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                      ),
                      child: Text('%', style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: quickbillController.discountType.value == 'Percentage' ? Colors.white : AppColor.textPrimary,
                      )),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        const SizedBox(height: 16),

        // Customer Details
        ExpansionTile(
          title: const Text(
            'Customer Details (Optional)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          children: [
            TextField(
              controller: quickbillController.customerNameController,
              onChanged: (value) =>
                  quickbillController.customerName.value = value,
              decoration: InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person_outline),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quickbillController.customerPhoneController,
              onChanged: (value) =>
                  quickbillController.customerPhone.value = value,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.phone_outlined),
                isDense: true,
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Payment Method
        Obx(() {
          final isSplit =
              quickbillController.selectedPaymentType.value == 'Split';

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  /// SPLIT → SHOW BOTH
                  if (isSplit)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Cash + Online',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColor.success,
                        ),
                      ),
                    )
                  /// FULL → USER SELECTS
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Cash'),
                              value: 'Cash',
                              groupValue:
                                  quickbillController.paymentMethod.value,
                              onChanged: (val) =>
                                  quickbillController.paymentMethod.value =
                                      val!,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Online'),
                              value: 'Online',
                              groupValue:
                                  quickbillController.paymentMethod.value,
                              onChanged: (val) =>
                                  quickbillController.paymentMethod.value =
                                      val!,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),

        // Payment Type
        Obx(
          () => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Full'),
                          value: 'Full',
                          groupValue:
                              quickbillController.selectedPaymentType.value,
                          onChanged: (val) {
                            quickbillController.selectedPaymentType.value =
                                val!;
                            quickbillController.paymentMethod.value =
                                'Cash'; // default
                            final total = quickbillController.calculateTotal();
                            quickbillController.cashReceived.value = total
                                .toStringAsFixed(2);
                            quickbillController.onlineReceived.value = '0';
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Split'),
                          value: 'Split',
                          groupValue:
                              quickbillController.selectedPaymentType.value,
                          onChanged: (val) {
                            quickbillController.selectedPaymentType.value =
                                val!;
                            quickbillController.paymentMethod.value =
                                'Both'; // 🔥 IMPORTANT
                            quickbillController.cashReceived.value = '';
                            quickbillController.onlineReceived.value = '';
                          },
                        ),
                      ),
                    ],
                  ),

                  /// SPLIT PAYMENT FIELDS
                  if (quickbillController.selectedPaymentType.value ==
                      'Split') ...[
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: quickbillController.cashReceivedController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cash Received',
                        prefixIcon: const Icon(Icons.money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          quickbillController.cashReceived.value = v,
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: quickbillController.onlineReceivedController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Online Received',
                        prefixIcon: const Icon(Icons.qr_code),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          quickbillController.onlineReceived.value = v,
                    ),

                    const SizedBox(height: 8),

                    Obx(() {
                      final cash =
                          double.tryParse(
                            quickbillController.cashReceived.value,
                          ) ??
                          0;
                      final online =
                          double.tryParse(
                            quickbillController.onlineReceived.value,
                          ) ??
                          0;
                      final total = quickbillController.calculateTotal();

                      return Text(
                        'Total Received: ₹${(cash + online).toStringAsFixed(2)} / ₹${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (cash + online) == total
                              ? AppColor.success
                              : AppColor.error,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Total Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Obx(
                () => Text(
                  '₹${quickbillController.calculateTotal().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _generateInvoice(context),
            icon: const Icon(Icons.receipt_long),
            label: const Text(
              'Generate Invoice',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _generateInvoice(BuildContext context) async {
    try {
      final billData = await quickbillController.createBill();
      if (billData != null) {
        final pdf = pw.Document();
        final fontData = await rootBundle.load(
          'assets/fonts/Roboto-Regular.ttf',
        );
        final robotoFont = pw.Font.ttf(fontData);
        pdf.addPage(
          pw.Page(build: (context) => _buildPDFContent(billData, robotoFont)),
        );

        // Platform specific preview logic
        if (Platform.isWindows) {
          // --- WINDOWS PREVIEW (using printing package) ---
          await Get.dialog(
            Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 800,
                  maxHeight: 800,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Invoice #${billData['invoiceNumber']} Preview',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              if (Get.isDialogOpen ?? false) Get.back();
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PdfPreview(
                        build: (format) => pdf.save(),
                        allowPrinting: false,
                        allowSharing: false, // Cleaner UI
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        // Removed custom action from toolbar\
                        initialPageFormat: PdfPageFormat(
                          80 * PdfPageFormat.mm,
                          double.infinity,
                          marginAll: 5 * PdfPageFormat.mm,
                        ),
                        actions:
                            const [], // Explicitly remove any other actions
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              if (Get.isDialogOpen ?? false) Get.back();
                            },
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              if (kIsWeb) {
                                if (Get.isDialogOpen ?? false) Get.back();
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Not supported on Web'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              
                              if (!printerController.isConnected.value) {
                                if (Get.isDialogOpen ?? false) Get.back();
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('No printer connected'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              try {
                                await quickbillController.printInvoice(
                                  billData,
                                );
                                
                                if (Get.isDialogOpen ?? false) Get.back();
                                
                                developer.log('[Home] PrintInvoice completed');
                                
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Invoice printed successfully'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              } catch (e) {
                                developer.log(
                                  '[Home] Print from preview failed: $e',
                                  level: 1000,
                                );
                                
                                if (Get.isDialogOpen ?? false) Get.back();
                                
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to print invoice'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            child: const Text('Print'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // --- ANDROID/ORIGINAL PREVIEW (using flutter_pdfview) ---
          final dir = await getTemporaryDirectory();
          final file = File(
            '${dir.path}/invoice_${billData['invoiceNumber']}.pdf',
          );
          await file.writeAsBytes(await pdf.save());

          await Get.dialog(
            Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                  maxHeight: 700,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Invoice #${billData['invoiceNumber']} Preview',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: PDFView(filePath: file.path, enableSwipe: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              if (Get.isDialogOpen ?? false) Get.back();
                            },
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              if (kIsWeb) {
                                if (Get.isDialogOpen ?? false) Get.back();
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Not supported on Web'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              
                              if (!printerController.isConnected.value) {
                                if (Get.isDialogOpen ?? false) Get.back();
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('No printer connected'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              try {
                                await quickbillController.printInvoice(
                                  billData,
                                );
                                
                                if (Get.isDialogOpen ?? false) Get.back();
                                
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Invoice printed successfully'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              } catch (e) {
                                if (Get.isDialogOpen ?? false) Get.back();
                                
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to print invoice'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            child: const Text('Print'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await file.delete();
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate preview: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  pw.Widget _buildPDFContent(
    Map<String, dynamic> billData,
    pw.Font robotoFont,
  ) {
    final subtotal = quickbillController.calculateBillSubtotal(billData);
    final discount = quickbillController.calculateBillDiscount(billData);
    final finalTotal = (subtotal - discount).clamp(0, double.infinity);
    final createdAt = DateTime.parse(billData['createdAt']).toLocal();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'FINE FOODS CRAFTS & GIFT',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            font: robotoFont,
          ),
        ),
        pw.Text(
          'Main Road Alathur, 7907609118',
          style: pw.TextStyle(font: robotoFont),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Invoice #${billData['invoiceNumber']}',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            font: robotoFont,
          ),
        ),
        pw.Text('Date: $formattedDate', style: pw.TextStyle(font: robotoFont)),
        pw.Text(
          'Customer: ${billData['customerName']}',
          style: pw.TextStyle(font: robotoFont),
        ),
        if (billData['customerPhone'].isNotEmpty)
          pw.Text(
            'Phone: ${billData['customerPhone']}',
            style: pw.TextStyle(font: robotoFont),
          ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Products:',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: robotoFont,
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: ['Product', 'Qty', 'Type', 'Price', 'Total']
                  .map(
                    (text) => pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        text,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: robotoFont,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            ...billData['products'].map<pw.TableRow>(
              (product) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      product['productName'],
                      style: pw.TextStyle(font: robotoFont),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      product['quantity'].toString(),
                      style: pw.TextStyle(font: robotoFont),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      product['type'],
                      style: pw.TextStyle(font: robotoFont),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '₹${product['price'].toStringAsFixed(2)}',
                      style: pw.TextStyle(font: robotoFont),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '₹${product['total'].toStringAsFixed(2)}',
                      style: pw.TextStyle(font: robotoFont),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Subtotal: ₹${subtotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: robotoFont),
                ),
                if (discount > 0)
                  pw.Text(
                    'Discount: ₹${discount.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: robotoFont),
                  ),
                pw.Text(
                  'Total: ₹${finalTotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: robotoFont,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Items: ${billData['itemCount']}',
          style: pw.TextStyle(font: robotoFont),
        ),
      ],
    );
  }
}

class ProductInputForm extends StatefulWidget {
  final QuickbillController controller;

  const ProductInputForm({required this.controller, super.key});

  @override
  State<ProductInputForm> createState() => _ProductInputFormState();
}

class _ProductInputFormState extends State<ProductInputForm> {
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: widget.controller.productNameController,
            decoration: InputDecoration(
              labelText: 'Product Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.label_outline),
              isDense: true,
            ),
            validator: (value) =>
                value!.isEmpty ? 'Product name cannot be empty' : null,
          ),
          const SizedBox(height: 12),
          Obx(
            () => DropdownButtonFormField<String>(
              value: widget.controller.selectedType.value,
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              items: ['unit', 'kg', 'meter', 'pack']
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) {
                widget.controller.selectedType.value = value!;
              },
              validator: (value) => value == null ? 'Select a type' : null,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.controller.productQuantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.numbers_outlined),
              isDense: true,
            ),
            validator: (value) {
              if (value!.isEmpty) return 'Quantity cannot be empty';
              final qty = double.tryParse(value);
              return qty == null || qty <= 0 ? 'Enter a valid quantity' : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.controller.productPriceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Price',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.attach_money_outlined),
              isDense: true,
            ),
            validator: (value) {
              if (value!.isEmpty) return 'Price cannot be empty';
              final price = double.tryParse(value);
              return price == null || price <= 0 ? 'Enter a valid price' : null;
            },
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  FocusScope.of(context).unfocus();
                  
                  widget.controller.addProduct(
                    name: widget.controller.productNameController.text.trim(),
                    price: double.parse(widget.controller.productPriceController.text.trim()),
                    quantity: double.parse(widget.controller.productQuantityController.text.trim()),
                    type: widget.controller.selectedType.value,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product added to cart'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please correct the input errors'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add to Cart',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
