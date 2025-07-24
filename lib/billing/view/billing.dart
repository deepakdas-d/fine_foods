// ignore_for_file: unused_local_variable

import 'package:fine_foods/billing/controller/billing_controller.dart';
import 'package:fine_foods/billing/view/billing_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fine_foods/invoice_generator/models/product_models.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BillingController controller = Get.put(BillingController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFD700),
        title: Text("Billing"),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              Get.to(() => BillingList());
            },
            icon: Icon(Icons.list),
          ),
        ],
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Customer Details Section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: controller.customerName,
                              decoration: InputDecoration(
                                labelText: 'Customer Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.person),
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
                                prefixIcon: const Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Product Selection Section
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Select Products',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Total: \$${controller.calculateTotal().toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: controller.products.length,
                                itemBuilder: (context, index) {
                                  final product = controller.products[index];
                                  return ProductSelectionTile(
                                    product: product,
                                    controller: controller,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Create Bill Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            controller.selectedProducts.isEmpty ||
                                controller.isLoading.value
                            ? null
                            : () => controller.createBill(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Bill',
                          style: TextStyle(fontSize: 18),
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

class ProductSelectionTile extends StatelessWidget {
  final Product product;
  final BillingController controller;

  const ProductSelectionTile({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Obx(
      () => ListTile(
        enabled: product.count > 0,
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: product.count > 0 ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          'Price: \$${product.price.toStringAsFixed(2)} | Stock: ${product.count}',
          style: TextStyle(
            color: product.count > 0 ? Colors.black54 : Colors.grey,
          ),
        ),
        trailing: product.count > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: screenWidth * 0.1,
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => controller.decreaseQuantity(product),
                  ),
                  Text(
                    '${controller.getSelectedQuantity(product)}',
                    style: TextStyle(fontSize: screenWidth * 0.1),
                  ),
                  IconButton(
                    iconSize: screenWidth * 0.1,

                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => controller.increaseQuantity(product),
                  ),
                ],
              )
            : const Text('Out of Stock', style: TextStyle(color: Colors.red)),
        onTap: product.count > 0
            ? () {
                if (controller.getSelectedQuantity(product) == 0) {
                  controller.increaseQuantity(product);
                }
              }
            : null,
      ),
    );
  }
}
