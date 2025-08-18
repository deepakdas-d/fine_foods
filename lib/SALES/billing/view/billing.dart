import 'package:fine_foods/SALES/billing/controller/billing_controller.dart';
import 'package:fine_foods/SALES/billing/view/billing_list.dart';
import 'package:fine_foods/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:pdf/widgets.dart' as pw; // includes PdfGoogleFonts
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:developer' as developer;

class BillingScreen extends StatelessWidget {
  BillingScreen({super.key});

  final controller = Get.put(BillingController());

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(controller),
      body: Obx(
        () => controller.isLoading.value
            ? _buildLoadingState()
            : Row(
                children: [
                  _buildProductsArea(controller, screenWidth),
                  if (isLargeScreen) _buildCartSidebar(controller),
                ],
              ),
      ),
      floatingActionButton: !isLargeScreen
          ? _buildFAB(controller, context)
          : null,
    );
  }

  AppBar _buildAppBar(BillingController controller) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFFFD700),
      title: const Text(
        "Point of Sale",
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      foregroundColor: Colors.white,
      actions: [
        Obx(
          () => Stack(
            children: [
              IconButton(
                onPressed: () => _showCartSheet(Get.context!, controller),
                icon: const Icon(Icons.shopping_cart_outlined, size: 26),
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
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${controller.selectedProducts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.to(() => BillingList()),
          icon: const Icon(Icons.receipt_long_outlined, size: 26),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Loading products..."),
        ],
      ),
    );
  }

  Widget _buildProductsArea(BillingController controller, double screenWidth) {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          _buildSearchBar(controller),
          Expanded(
            child: Obx(
              () => controller.filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : _buildProductsList(controller, screenWidth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BillingController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: controller.searchProducts,
        decoration: InputDecoration(
          hintText: 'Search products by name...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => controller.searchProducts(''),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No products found",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(BillingController controller, double screenWidth) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.filteredProducts.length,
      itemBuilder: (context, index) {
        final product = controller.filteredProducts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16), // spacing between items
          child: _buildProductCard(product, controller),
        );
      },
    );
  }

  Widget _buildProductCard(Product product, BillingController controller) {
    return Obx(() {
      final isSelected = controller.getSelectedQuantity(product) > 0;
      final isOutOfStock = product.count <= 0;
      final quantity = controller.getSelectedQuantity(product);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD700)
                : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
              blurRadius: isSelected ? 15 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isOutOfStock
                ? null
                : () => controller.increaseQuantity(product),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Icon
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
                      color: isOutOfStock
                          ? Colors.grey
                          : const Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Product Name
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isOutOfStock ? Colors.grey : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Price & Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isOutOfStock
                              ? Colors.grey
                              : const Color(0xFF1565C0),
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
                          isOutOfStock
                              ? 'Out of Stock'
                              : 'Stock: ${product.count}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isOutOfStock ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Add / Quantity Buttons
                  if (!isOutOfStock)
                    isSelected
                        ? Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    controller.decreaseQuantity(product),
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.red,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
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
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  controller.increaseQuantity(product),
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                size: 18,
                              ),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCartSidebar(BillingController controller) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: _buildCartContent(controller),
    );
  }

  Widget _buildCartContent(BillingController controller) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildCartHeader(controller),
          Expanded(
            child: Obx(
              () => controller.selectedProducts.isEmpty
                  ? _buildEmptyCart()
                  : _buildCartItems(controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartHeader(BillingController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFFFD700),
        borderRadius: BorderRadius.only(topRight: Radius.circular(0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: Colors.white),
          const SizedBox(width: 12),
          const Text(
            'Shopping Cart',
            style: TextStyle(
              color: Colors.white,
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
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Cart is empty',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Add products to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(BillingController controller) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.selectedProducts.length,
            itemBuilder: (context, index) {
              final productId = controller.selectedProducts.keys.elementAt(
                index,
              );
              final product = controller.products.firstWhere(
                (p) => p.id == productId,
              );
              final quantity = controller.selectedProducts[productId]!;
              return _buildCartItem(product, quantity, controller);
            },
          ),
        ),
        _buildCheckoutSection(controller),
      ],
    );
  }

  Widget _buildCartItem(
    Product product,
    int quantity,
    BillingController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\₹${product.price.toStringAsFixed(2)} each',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => controller.increaseQuantity(product),
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFFFFD700),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '\₹${(product.price * quantity).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFFFFD700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(BillingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller.customerDiscount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Discount',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.discount_outlined),
              isDense: true,
            ),
          ),
          ExpansionTile(
            title: const Text(
              'Customer Details (Optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: controller.customerName,
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
                controller: controller.customerPhone,
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
              const SizedBox(height: 16),
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
                    '\₹${controller.calculateTotal().toStringAsFixed(2)}',
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
              onPressed: controller.selectedProducts.isEmpty
                  ? null
                  : () => _generateInvoice(controller),
              icon: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.receipt_long),
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
  }

  Widget? _buildFAB(BillingController controller, BuildContext context) {
    return Obx(
      () => controller.selectedProducts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCartSheet(context, controller),
              backgroundColor: const Color(0xFFFFD700),
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                'Cart (${controller.selectedProducts.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  void _showCartSheet(BuildContext context, BillingController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
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
              Expanded(child: _buildCartContent(controller)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateInvoice(BillingController controller) async {
    try {
      developer.log("Creating bill");
      final billData = await controller.createBill();
      if (billData != null) {
        final pdf = pw.Document();
        final fontData = await rootBundle.load(
          'assets/fonts/Roboto-Regular.ttf',
        );
        final robotoFont = pw.Font.ttf(fontData);
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) =>
                _buildPDFContent(billData, robotoFont),
          ),
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
                    child: PDFView(
                      filePath: file.path,
                      enableSwipe: true,
                      autoSpacing: true,
                      pageFling: true,
                      onError: (error) {
                        developer.log('PDFView error: $error');
                        Get.snackbar(
                          'Error',
                          'Failed to load PDF preview: $error',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final printerController = Get.put(
                              PrinterController(),
                            );

                            if (!printerController.isConnected.value) {
                              Get.snackbar(
                                'Error',
                                'No printer connected',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            try {
                              await controller.printInvoice(billData);
                              Get.back();
                              Get.snackbar(
                                'Success',
                                'Invoice printed successfully',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            } catch (e) {
                              developer.log('Print error: $e');
                              Get.snackbar(
                                'Error',
                                'Failed to print: $e',
                                snackPosition: SnackPosition.BOTTOM,
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
      developer.log('Error: $e');
      Get.snackbar(
        'Error',
        'Failed to generate preview: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  pw.Widget _buildPDFContent(
    Map<String, dynamic> billData,
    pw.Font robotoFont,
  ) {
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
          children: [
            pw.TableRow(
              children: ['Product', 'Qty', 'Price', 'Total']
                  .map(
                    (text) => pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        text,
                        style: pw.TextStyle(font: robotoFont),
                      ),
                    ),
                  )
                  .toList(),
            ),
            ...billData['products'].values.map(
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
                      '₹${product['price']}',
                      style: pw.TextStyle(font: robotoFont),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '₹${product['total']}',
                      style: pw.TextStyle(font: robotoFont),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Total: ₹${billData['total']}',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: robotoFont,
          ),
        ),
        pw.Text(
          'Items: ${billData['itemCount']}',
          style: pw.TextStyle(font: robotoFont),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Date: ${billData['createdAt']}',
          style: pw.TextStyle(font: robotoFont),
        ),
      ],
    );
  }
}
