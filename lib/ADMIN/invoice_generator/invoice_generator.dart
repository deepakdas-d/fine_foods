// ignore_for_file: unused_local_variable

import 'package:fine_foods/ADMIN/invoice_generator/invoice_controller.dart';
import 'package:fine_foods/appcolor.dart';
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
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Invoice Generator',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24, color: AppColor.background),
        ),
        backgroundColor: AppColor.primary,
        centerTitle: true,
        foregroundColor: AppColor.background,
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
                      color: AppColor.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Source',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppColor.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: controller.selectedCollection.value,
                              decoration: InputDecoration(
                                labelText: 'Collection',
                                labelStyle: GoogleFonts.poppins(color: AppColor.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColor.textSecondary),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColor.textSecondary),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColor.primary),
                                ),
                                prefixIcon: const Icon(
                                  Icons.category,
                                  color: AppColor.primary,
                                ),
                                filled: true,
                                fillColor: AppColor.background,
                              ),
                              dropdownColor: AppColor.surface,
                              style: GoogleFonts.poppins(color: AppColor.textPrimary),
                              items: ['inventory', 'products'].map((
                                String collection,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: collection,
                                  child: Text(
                                    collection.capitalizeFirst!,
                                    style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary),
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
                      color: AppColor.surface,
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
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: AppColor.primary,
                                  ),
                                ),
                                if (controller.products.isNotEmpty)
                                  TextButton(
                                    onPressed: controller.clearAllProducts,
                                    child: Text(
                                      'Clear All',
                                      style: GoogleFonts.poppins(
                                        color: AppColor.error,
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
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: AppColor.textSecondary,
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
                                        color: AppColor.background,
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: AppColor.primary.withOpacity(0.2),
                                            child: Text(
                                              product.name[0].toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                color: AppColor.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            product.name,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColor.textPrimary,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Qty: ${product.count} ${product.quantityType} × ₹${product.price.toStringAsFixed(2)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: AppColor.textSecondary,
                                            ),
                                          ),
                                          trailing: Text(
                                            '₹${product.totalPrice.toStringAsFixed(2)}',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColor.textPrimary,
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
                      color: AppColor.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount:',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                                Text(
                                  '₹${controller.totalAmount.value.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColor.success,
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
                                      backgroundColor: AppColor.success,
                                      foregroundColor: AppColor.textPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      disabledBackgroundColor: AppColor.success.withOpacity(0.3),
                                    ),
                                    child: Text(
                                      'Generate from Inventory',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.textOnPrimary, // Assuming white/black on success? white is safe
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
                                      backgroundColor: AppColor.primary,
                                      foregroundColor: AppColor.background,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      disabledBackgroundColor: AppColor.primary.withOpacity(0.3),
                                    ),
                                    child: Text(
                                      'Generate from Products',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.background,
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
