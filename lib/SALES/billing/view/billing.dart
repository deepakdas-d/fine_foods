import 'package:fine_foods/SALES/billing/controller/billing_controller.dart';
import 'package:fine_foods/ADMIN/Bills/billing_list_controller.dart';
import 'package:fine_foods/home/printer_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:fine_foods/appcolor.dart';
import 'package:printing/printing.dart';

class BillingScreen extends StatelessWidget {
  final controller = Get.put(BillingController());
  final controllerlist = Get.put(BillListController());

  BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: _buildAppBar(),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  _buildProductsArea(),
                  if (isLargeScreen) _buildCartSidebar(),
                ],
              ),
      ),
      floatingActionButton: !isLargeScreen ? _buildFAB(context) : null,
    );
  }

  AppBar _buildAppBar() => AppBar(
    elevation: 0,
    backgroundColor: AppColor.background,
    title: const Text(
      "Point of Sale",
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColor.textPrimary,
      ),
    ),
    foregroundColor: AppColor.textPrimary,
    actions: [
      Obx(
        () => Stack(
          children: [
            IconButton(
              onPressed: () => _showCartSheet(Get.context!),
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: AppColor.textPrimary,
              ),
            ),
            if (controller.selectedProducts.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${controller.selectedProducts.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _buildProductsArea() => Expanded(
    flex: 3,
    child: Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: Obx(
            () => controller.filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      "No products found",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.filteredProducts.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildProductCard(
                        controller.filteredProducts[index],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSearchBar() => Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
      ],
    ),
    child: TextField(
      onChanged: controller.searchProducts,
      decoration: const InputDecoration(
        hintText: 'Search products...',
        prefixIcon: Icon(Icons.search, color: Color(0xFFFFD700)),
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(16),
      ),
    ),
  );

  Widget _buildProductCard(Product product) => Obx(() {
    final isSelected = controller.getSelectedQuantity(product) > 0;
    final isOutOfStock = product.count <= 0;
    final quantity = controller.getSelectedQuantity(product);

    final currentPrice = controller.getCustomPrice(product);

    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColor.primary
              : AppColor.textSecondary.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isOutOfStock ? null : () => controller.increaseQuantity(product),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? Colors.grey.withOpacity(0.3)
                      : const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 32,
                  color: isOutOfStock ? Colors.grey : const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isOutOfStock
                      ? AppColor.textSecondary
                      : AppColor.textPrimary,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 150,
                    child: TextField(
                      enabled: !isOutOfStock,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '$currentPrice',
                        prefixText: '₹',
                        hintText: product.price.toStringAsFixed(2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final newPrice =
                            double.tryParse(value) ?? product.price;
                        controller.setCustomPrice(product, newPrice);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOutOfStock ? 'Out of Stock' : 'Stock: ${product.count}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOutOfStock ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!isOutOfStock)
                isSelected
                    ? Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                controller.decreaseQuantity(product),
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.red,
                          ),
                          Expanded(
                            child: Text(
                              '$quantity',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                controller.increaseQuantity(product),
                            icon: const Icon(Icons.add_circle_outline),
                            color: const Color(0xFFFFD700),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => controller.increaseQuantity(product),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  });

  Widget _buildCartSidebar() => Container(
    width: 350,
    decoration: BoxDecoration(
      color: AppColor.surface,
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
      ],
    ),
    child: _buildCartContent(),
  );

  Widget _buildCartContent() => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Color(0xFFFFD700)),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white),
            const SizedBox(width: 12),
            const Text(
              'Shopping Cart',
              style: TextStyle(
                color: AppColor.textOnPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Obx(
              () => Text(
                '${controller.selectedProducts.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: Obx(
          () => controller.selectedProducts.isEmpty
              ? const Center(
                  child: Text(
                    'Cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.selectedProducts.length,
                        itemBuilder: (context, index) {
                          final productId = controller.selectedProducts.keys
                              .elementAt(index);
                          final product = controller.products.firstWhere(
                            (p) => p.id == productId,
                          );
                          final quantity =
                              controller.selectedProducts[productId]!;
                          return _buildCartItem(product, quantity);
                        },
                      ),
                    ),
                    _buildCheckoutSection(),
                  ],
                ),
        ),
      ),
    ],
  );

  Widget _buildCartItem(Product product, int quantity) {
    final currentPrice = controller.getCustomPrice(product);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.textSecondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFFFFD700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '$currentPrice',
                      prefixText: '₹',
                      hintText: controller
                          .getCustomPrice(product)
                          .toStringAsFixed(2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final newPrice = double.tryParse(value) ?? product.price;
                      controller.setCustomPrice(product, newPrice);
                    },
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => controller.decreaseQuantity(product),
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red,
              ),
              Text(
                '$quantity',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => controller.increaseQuantity(product),
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFFFFD700),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '₹${(controller.getCustomPrice(product) * quantity).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    decoration: BoxDecoration(
      color: AppColor.background,
      border: Border(
        top: BorderSide(color: AppColor.textSecondary.withOpacity(0.2)),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact Total Display First (Always Visible)
        Container(
          padding: const EdgeInsets.all(12),
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
                  '₹${controller.calculateTotal().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Collapsible Advanced Options
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: const Text(
            'Payment & Details',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Obx(() {
            final type = controller.selectedPaymentType.value;
            final method = controller.paymentMethod.value;
            return Text(
              type == 'Split' ? 'Split Payment' : '$type • $method',
              style: TextStyle(fontSize: 14, color: AppColor.textSecondary),
            );
          }),
          children: [
            // Discount
            TextFormField(
              initialValue: controller.customerDiscount.value.isEmpty
                  ? null
                  : controller.customerDiscount.value,
              onChanged: (v) => controller.customerDiscount.value = v,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Discount (₹)',
                prefixIcon: const Icon(Icons.discount_outlined, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Customer Details (Compact Inline)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.customerName,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.customerPhone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Method & Type (Compact Cards)
            Obx(() {
              final isSplit = controller.selectedPaymentType.value == 'Split';
              return Column(
                children: [
                  // Payment Type
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Full', label: Text('Full')),
                      ButtonSegment(value: 'Split', label: Text('Split')),
                    ],
                    selected: {controller.selectedPaymentType.value},
                    onSelectionChanged: (set) {
                      final val = set.first;
                      controller.selectedPaymentType.value = val;
                      if (val == 'Full') {
                        controller.paymentMethod.value = 'Cash';
                        controller.cashReceived.value = controller
                            .calculateTotal()
                            .toStringAsFixed(2);
                        controller.onlineReceived.value = '0';
                      } else {
                        controller.cashReceived.value = '';
                        controller.onlineReceived.value = '';
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  if (!isSplit)
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Cash', label: Text('Cash')),
                        ButtonSegment(value: 'Online', label: Text('Online')),
                      ],
                      selected: {controller.paymentMethod.value},
                      onSelectionChanged: (set) =>
                          controller.paymentMethod.value = set.first,
                    ),

                  if (isSplit) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cash',
                              prefixIcon: const Icon(Icons.money, size: 18),
                              isDense: true,
                            ),
                            onChanged: (v) => controller.cashReceived.value = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Online',
                              prefixIcon: const Icon(Icons.qr_code, size: 18),
                              isDense: true,
                            ),
                            onChanged: (v) =>
                                controller.onlineReceived.value = v,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final cash =
                          double.tryParse(controller.cashReceived.value) ?? 0;
                      final online =
                          double.tryParse(controller.onlineReceived.value) ?? 0;
                      final total = controller.calculateTotal();
                      final received = cash + online;
                      return Text(
                        'Received: ₹${received.toStringAsFixed(2)} / ₹${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: received >= total
                              ? AppColor.success
                              : AppColor.error,
                        ),
                      );
                    }),
                  ],
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 12),

        // Generate Invoice Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.selectedProducts.isEmpty
                ? null
                : _generateInvoice,
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

  Widget? _buildFAB(BuildContext context) => Obx(
    () => controller.selectedProducts.isNotEmpty
        ? FloatingActionButton.extended(
            onPressed: () => _showCartSheet(context),
            backgroundColor: const Color(0xFFFFD700),
            icon: const Icon(Icons.shopping_cart, color: AppColor.background),
            label: Text(
              'Cart (${controller.selectedProducts.length})',
              style: TextStyle(color: AppColor.background),
            ),
          )
        : const SizedBox.shrink(),
  );

  void _showCartSheet(BuildContext context) => Get.bottomSheet(
    DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(child: _buildCartContent()),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );

  Future<void> _generateInvoice() async {
    try {
      final billData = await controller.createBill();
      if (billData == null) return;

      final pdf = pw.Document();
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final robotoFont = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.Page(build: (context) => _buildPDFContent(billData, robotoFont)),
      );

      // ================= WINDOWS =================
      if (Platform.isWindows) {
        await Get.dialog(
          Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
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
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PdfPreview(
                      build: (format) => pdf.save(),
                      allowPrinting: false,
                      allowSharing: false,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      initialPageFormat: PdfPageFormat(
                        80 * PdfPageFormat.mm,
                        double.infinity,
                        marginAll: 5 * PdfPageFormat.mm,
                      ),
                      actions: const [],
                    ),
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
                            final printerController =
                                Get.find<PrinterController>();

                            if (kIsWeb) {
                              Get.snackbar(
                                'Web Mode',
                                'Not supported on Web',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                              return;
                            }

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
                              await controller.printInvoice(billData);
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
      }
      // ================= ANDROID =================
      else {
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
                            final printerController =
                                Get.find<PrinterController>();

                            if (kIsWeb) {
                              Get.snackbar(
                                'Web Mode',
                                'Bluetooth printing not supported on Web',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                              return;
                            }

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
                              await controller.printInvoice(billData);
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
    final subtotal = controllerlist.calculateBillSubtotal(billData);
    final discount = controllerlist.calculateBillDiscount(billData);
    final finalTotal = (subtotal - discount).clamp(0, double.infinity);

    final createdAt = DateTime.parse(billData['createdAt']).toLocal();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Invoice #${billData['invoiceNumber']}',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            font: robotoFont,
          ),
        ),
        pw.SizedBox(height: 16),
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
          columnWidths: {
            0: const pw.FlexColumnWidth(4), // Product name - wider
            1: const pw.FlexColumnWidth(1), // Qty
            2: const pw.FlexColumnWidth(2), // Price
            3: const pw.FlexColumnWidth(2), // Total
          },
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            // Header Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: ['Product', 'Qty', 'Price', 'Total']
                  .map(
                    (text) => pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        text,
                        style: pw.TextStyle(
                          font: robotoFont,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            // Product Rows - FIXED: removed .values and added .toList()
            ...billData['products']
                .map<pw.TableRow>(
                  (product) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          product['productName'] ?? '',
                          style: pw.TextStyle(font: robotoFont),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          product['quantity'].toString(),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: robotoFont),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '₹${(product['price'] as num).toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(font: robotoFont),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '₹${(product['total'] as num).toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: robotoFont,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
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
        pw.Text('Date: $formattedDate', style: pw.TextStyle(font: robotoFont)),
      ],
    );
  }
}
