import 'package:fine_foods/billing/controller/billing_controller.dart';
import 'package:fine_foods/billing/view/billing_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fine_foods/invoice_generator/models/product_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:developer' as developer;

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BillingController controller = Get.put(BillingController());
    // ignore: unused_local_variable
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFD700),
        title: const Text(
          "Point of Sale",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        actions: [
          // Cart Icon with Badge
          Obx(
            () => Stack(
              children: [
                IconButton(
                  onPressed: () => _showCartSheet(context, controller),
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
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Loading products..."),
                  ],
                ),
              )
            : Row(
                children: [
                  // Main Product Selection Area
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
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
                            onChanged: (value) =>
                                controller.searchProducts(value),
                            decoration: InputDecoration(
                              hintText: 'Search products by name...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFFFFD700),
                              ),
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
                        ),
                        // Products Grid
                        Expanded(
                          child: Obx(
                            () => controller.filteredProducts.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "No products found",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: screenWidth > 1200
                                              ? 4
                                              : screenWidth > 800
                                              ? 3
                                              : 2,
                                          childAspectRatio: 0.8,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                        ),
                                    itemCount:
                                        controller.filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      final product =
                                          controller.filteredProducts[index];
                                      return ProductCard(
                                        product: product,
                                        controller: controller,
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cart Sidebar (for larger screens)
                  if (screenWidth > 800)
                    Container(
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
                      child: CartSidebar(controller: controller),
                    ),
                ],
              ),
      ),
      // Floating Action Button for smaller screens
      floatingActionButton: screenWidth <= 800
          ? Obx(
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
            )
          : null,
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
          child: CartSheet(
            controller: controller,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final BillingController controller;

  const ProductCard({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = controller.getSelectedQuantity(product) > 0;
      final isOutOfStock = product.count <= 0;

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
                  // Product Icon/Image placeholder
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
                  Expanded(
                    child: Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isOutOfStock ? Colors.grey : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price and Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
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
                  // Add to Cart Button
                  if (!isOutOfStock)
                    Row(
                      children: [
                        if (isSelected) ...[
                          Expanded(
                            child: Row(
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
                                    '${controller.getSelectedQuantity(product)}',
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
                            ),
                          ),
                        ] else
                          Expanded(
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
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

//cart widget

class CartSidebar extends StatelessWidget {
  final BillingController controller;

  const CartSidebar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
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
        ),
        // Cart Items
        Expanded(
          child: Obx(() {
            if (controller.selectedProducts.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
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

            return Column(
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
                      final quantity = controller.selectedProducts[productId]!;

                      return CartItem(
                        product: product,
                        quantity: quantity,
                        controller: controller,
                      );
                    },
                  ),
                ),
                // Customer Details & Checkout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Customer Details (Optional)
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
                      // Total
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Obx(
                              () => Text(
                                '\$${controller.calculateTotal().toStringAsFixed(2)}',
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
                      // Create Bill Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.selectedProducts.isEmpty
                              ? null
                              : () async {
                                  try {
                                    developer.log("Creating bill");
                                    final billData = await controller
                                        .createBill();
                                    if (billData != null) {
                                      // Generate PDF
                                      final pdf = pw.Document();
                                      pdf.addPage(
                                        pw.Page(
                                          build: (pw.Context context) {
                                            return pw.Column(
                                              crossAxisAlignment:
                                                  pw.CrossAxisAlignment.start,
                                              children: [
                                                pw.Text(
                                                  'Invoice #${billData['invoiceNumber']}',
                                                  style: pw.TextStyle(
                                                    fontSize: 24,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.SizedBox(height: 16),
                                                pw.Text(
                                                  'Customer: ${billData['customerName']}',
                                                ),
                                                if (billData['customerPhone']
                                                    .isNotEmpty)
                                                  pw.Text(
                                                    'Phone: ${billData['customerPhone']}',
                                                  ),
                                                pw.SizedBox(height: 16),
                                                pw.Text(
                                                  'Products:',
                                                  style: pw.TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.Table(
                                                  border: pw.TableBorder.all(),
                                                  children: [
                                                    pw.TableRow(
                                                      children: [
                                                        pw.Padding(
                                                          padding:
                                                              const pw.EdgeInsets.all(
                                                                8,
                                                              ),
                                                          child: pw.Text(
                                                            'Product',
                                                          ),
                                                        ),
                                                        pw.Padding(
                                                          padding:
                                                              const pw.EdgeInsets.all(
                                                                8,
                                                              ),
                                                          child: pw.Text('Qty'),
                                                        ),
                                                        pw.Padding(
                                                          padding:
                                                              const pw.EdgeInsets.all(
                                                                8,
                                                              ),
                                                          child: pw.Text(
                                                            'Price',
                                                          ),
                                                        ),
                                                        pw.Padding(
                                                          padding:
                                                              const pw.EdgeInsets.all(
                                                                8,
                                                              ),
                                                          child: pw.Text(
                                                            'Total',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    ...billData['products'].values.map(
                                                      (product) => pw.TableRow(
                                                        children: [
                                                          pw.Padding(
                                                            padding:
                                                                const pw.EdgeInsets.all(
                                                                  8,
                                                                ),
                                                            child: pw.Text(
                                                              product['productName'],
                                                            ),
                                                          ),
                                                          pw.Padding(
                                                            padding:
                                                                const pw.EdgeInsets.all(
                                                                  8,
                                                                ),
                                                            child: pw.Text(
                                                              product['quantity']
                                                                  .toString(),
                                                            ),
                                                          ),
                                                          pw.Padding(
                                                            padding:
                                                                const pw.EdgeInsets.all(
                                                                  8,
                                                                ),
                                                            child: pw.Text(
                                                              '\$${product['price']}',
                                                            ),
                                                          ),
                                                          pw.Padding(
                                                            padding:
                                                                const pw.EdgeInsets.all(
                                                                  8,
                                                                ),
                                                            child: pw.Text(
                                                              '\$${product['total']}',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                pw.SizedBox(height: 16),
                                                pw.Text(
                                                  'Total: \$${billData['total']}',
                                                  style: pw.TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.Text(
                                                  'Items: ${billData['itemCount']}',
                                                ),
                                                pw.SizedBox(height: 16),
                                                pw.Text(
                                                  'Date: ${billData['createdAt']}',
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      );

                                      // Save PDF to temporary file
                                      final dir = await getTemporaryDirectory();
                                      final file = File(
                                        '${dir.path}/invoice_${billData['invoiceNumber']}.pdf',
                                      );
                                      await file.writeAsBytes(await pdf.save());

                                      // Show preview dialog
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
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Text(
                                                    'Invoice #${billData['invoiceNumber']} Preview',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      developer.log(
                                                        'PDFView error: $error',
                                                      );
                                                      Get.snackbar(
                                                        'Error',
                                                        'Failed to load PDF preview: $error',
                                                        snackPosition:
                                                            SnackPosition
                                                                .BOTTOM,
                                                        backgroundColor:
                                                            Colors.red,
                                                        colorText: Colors.white,
                                                      );
                                                    },
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Get.back(),
                                                        child: const Text(
                                                          'Close',
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          try {
                                                            await Printing.layoutPdf(
                                                              onLayout:
                                                                  (
                                                                    PdfPageFormat
                                                                    format,
                                                                  ) async => pdf
                                                                      .save(),
                                                            );
                                                            Get.back();
                                                          } catch (e) {
                                                            developer.log(
                                                              'Print error: $e',
                                                            );
                                                            Get.snackbar(
                                                              'Error',
                                                              'Failed to print: $e',
                                                              snackPosition:
                                                                  SnackPosition
                                                                      .BOTTOM,
                                                              backgroundColor:
                                                                  Colors.red,
                                                              colorText:
                                                                  Colors.white,
                                                            );
                                                          }
                                                        },
                                                        child: const Text(
                                                          'Print',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );

                                      // Clean up temporary file
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
                                },
                          icon: controller.isLoading.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Icon(Icons.receipt_long),
                          label: const Text(
                            'Generate Invoice',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class CartSheet extends StatelessWidget {
  final BillingController controller;
  final ScrollController scrollController;

  const CartSheet({
    super.key,
    required this.controller,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 8),
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Content
        Expanded(child: CartSidebar(controller: controller)),
      ],
    );
  }
}

class CartItem extends StatelessWidget {
  final Product product;
  final int quantity;
  final BillingController controller;

  const CartItem({
    super.key,
    required this.product,
    required this.quantity,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
          // Product Icon
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
          // Product Details
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
                  '\$${product.price.toStringAsFixed(2)} each',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          // Quantity Controls
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
          // Total Price
          const SizedBox(width: 8),
          Text(
            '\$${(product.price * quantity).toStringAsFixed(2)}',
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
}
