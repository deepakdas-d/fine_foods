import 'dart:io';

import 'package:fine_foods/bluetooth_list.dart';
import 'package:fine_foods/home/printer_controller.dart';
import 'package:fine_foods/home/quickbill_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;

class Home extends StatelessWidget {
  Home({super.key});

  final printerController = Get.find<PrinterController>();
  final QuickbillController quickbillController = Get.put(
    QuickbillController(),
  );

  final RxBool isLoading = false.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        title: const Text(
          "Quick Bill",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        foregroundColor: Colors.black,
        actions: [
          if (!kIsWeb) // Hides everything on Web
            Obx(() {
              return Row(
                children: [
                  if (printerController.isConnected.value &&
                      printerController.printerName.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        printerController.printerName.value,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),

                  IconButton(
                    icon: Icon(
                      printerController.isConnected.value
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth,
                      color: printerController.isConnected.value
                          ? Colors.green
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
      color: Colors.grey[50],
      border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
    ),
    child: Column(
      children: [
        TextFormField(
          controller: TextEditingController(
            text: quickbillController.customerDiscount.value,
          ),
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

            final discount = double.tryParse(value.trim());
            if (discount == null || discount <= 0) {
              return 'Enter a valid discount > 0';
            }

            final total = quickbillController
                .calculateTotal(); // your total function
            if (discount > total) {
              return 'Discount cannot exceed total price ($total)';
            }

            return null;
          },
        ),

        ExpansionTile(
          title: const Text(
            'Customer Details (Optional)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          children: [
            TextField(
              controller: TextEditingController(
                text: quickbillController.customerName.value,
              ),
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
              controller: TextEditingController(
                text: quickbillController.customerPhone.value,
              ),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.1),
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
                    color: Color(0xFFFFD700),
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
              backgroundColor: const Color(0xFFFFD700),
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
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/invoice_${billData['invoiceNumber']}.pdf',
        );
        await file.writeAsBytes(await pdf.save());
        await Get.dialog(
          Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
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
                          onPressed: () => Get.back(closeOverlays: true),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (kIsWeb) {
                              // ----------- WEB MODE -----------
                              Get.snackbar(
                                'Web Mode',
                                'Bluetooth printers are not supported on Web. Please download the invoice instead.',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            // ----------- ANDROID / iOS MODE -----------
                            if (!printerController.isConnected.value) {
                              Get.snackbar(
                                'Error',
                                'No printer connected',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            try {
                              await quickbillController.printInvoice(billData);
                              Get.snackbar(
                                'Success',
                                'Invoice printed successfully',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                              Get.back(closeOverlays: true);
                            } catch (e) {
                              Get.snackbar(
                                'Error',
                                'Failed to print: $e',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
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
          'WRAPPIE CRAFTS & GIFTS',
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

class ProductInputForm extends StatelessWidget {
  final QuickbillController controller;

  const ProductInputForm({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: controller.productNameController.text,
    );
    final quantityController = TextEditingController(
      text: controller.productQuantityController.text,
    );
    final priceController = TextEditingController(
      text: controller.productPriceController.text,
    );
    String selectedType = controller.productTypeController.text;

    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
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
            onChanged: (value) => controller.productNameController.text = value,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: quantityController,
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
            onChanged: (value) =>
                controller.productQuantityController.text = value,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: priceController,
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
            onChanged: (value) =>
                controller.productPriceController.text = value,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            items: ['unit', 'kg', 'meter', 'pack']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) =>
                controller.productTypeController.text = value!,
            validator: (value) => value == null ? 'Select a type' : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  controller.addProduct(
                    name: nameController.text.trim(),
                    price: double.parse(priceController.text.trim()),
                    quantity: double.parse(quantityController.text.trim()),
                    type: selectedType,
                  );
                  nameController.clear();
                  quantityController.clear();
                  priceController.clear();
                  controller.productTypeController.text = 'unit';
                  controller.clearProductInputs();
                } else {
                  Get.snackbar(
                    'Error',
                    'Please correct the input errors',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
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
