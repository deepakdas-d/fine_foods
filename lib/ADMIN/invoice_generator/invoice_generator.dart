// ignore_for_file: unused_local_variable

import 'package:fine_foods/ADMIN/invoice_generator/invoice_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class InvoiceGenerator extends StatelessWidget {
  const InvoiceGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    final InvoiceController controller = Get.put(InvoiceController());
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Invoice Generator',
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: const Color(0xFFFFD700),
        centerTitle: true,
        foregroundColor: Colors.black87,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(screenHeight * 0.020),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Collection Selector
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Source',
                              style: GoogleFonts.k2d(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: controller.selectedCollection.value,
                              decoration: InputDecoration(
                                labelText: 'Collection',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(
                                  Icons.category,
                                  color: Color(0xFFFFD700),
                                ),
                                filled: true,
                                fillColor: Colors.blue[50],
                              ),
                              items: ['inventory', 'products'].map((
                                String collection,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: collection,
                                  child: Text(
                                    collection.capitalizeFirst!,
                                    style: GoogleFonts.k2d(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  controller.selectedCollection.value = value;
                                  controller.loadProducts();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Products List
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Products (${controller.products.length})',
                                  style: GoogleFonts.k2d(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                if (controller.products.isNotEmpty)
                                  TextButton(
                                    onPressed: controller.clearAllProducts,
                                    child: Text(
                                      'Clear All',
                                      style: GoogleFonts.k2d(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            controller.products.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Text(
                                        'No products available',
                                        style: GoogleFonts.k2d(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: controller.products.length,
                                    itemBuilder: (context, index) {
                                      final product =
                                          controller.products[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.blue[100],
                                            child: Text(
                                              product.name[0].toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            product.name,
                                            style: GoogleFonts.k2d(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Qty: ${product.count} ${product.quantityType} × ₹${product.price.toStringAsFixed(2)}',
                                            style: GoogleFonts.k2d(
                                              fontSize: 14,
                                            ),
                                          ),
                                          trailing: Text(
                                            '₹${product.totalPrice.toStringAsFixed(2)}',
                                            style: GoogleFonts.k2d(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Total and Generate Invoice Buttons
                    Card(
                      elevation: 4,
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount:',
                                  style: GoogleFonts.k2d(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  '₹${controller.totalAmount.value.toStringAsFixed(2)}',
                                  style: GoogleFonts.k2d(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        controller.products.isEmpty ||
                                            controller
                                                    .selectedCollection
                                                    .value !=
                                                'inventory'
                                        ? null
                                        : () => controller.generateInvoice(
                                            'inventory',
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Generate from Inventory',
                                      style: GoogleFonts.k2d(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        controller.products.isEmpty ||
                                            controller
                                                    .selectedCollection
                                                    .value !=
                                                'products'
                                        ? null
                                        : () => controller.generateInvoice(
                                            'products',
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Generate from Products',
                                      style: GoogleFonts.k2d(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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
                  ],
                ),
              ),
      ),
    );
  }
}
