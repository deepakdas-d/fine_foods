import 'package:fine_foods/ADMIN/Inventory/inventory_controller.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class Inventory extends StatelessWidget {
  const Inventory({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryController());

    return Scaffold(
      backgroundColor: AppColor.background, // Dark Background
      appBar: AppBar(
        title: Text(
          'Inventory Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24, color: AppColor.background),
        ),
        backgroundColor: AppColor.primary, // Yellow
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
            : Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColor.surface, width: 1), // Darker border
                  borderRadius: BorderRadius.circular(12),
                  // Removed shadow for flat dark design
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColor.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColor.primary.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'Total Value: ₹${controller.total.value.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColor.primary, // Yellow Text
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 600) {
                              return _buildDesktopTable(controller, context);
                            } else {
                              return _buildMobileList(controller, context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductModal(context, controller),
        backgroundColor: AppColor.primary,
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  void _showAddProductModal(
    BuildContext context,
    InventoryController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColor.surface, // Dark modal bg
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(
                      'Add Product',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColor.primary, // Yellow
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.productNameController,
                      style: GoogleFonts.poppins(color: AppColor.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        labelStyle: TextStyle(color: AppColor.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.shopping_bag,
                          color: AppColor.primary,
                        ),
                        filled: true,
                        fillColor: AppColor.background, // Darker input bg
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.productIdController,
                      style: GoogleFonts.poppins(color: AppColor.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Product Barcode',
                        labelStyle: TextStyle(color: AppColor.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.qr_code,
                          color: AppColor.primary,
                        ),
                        filled: true,
                        fillColor: AppColor.background,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: controller.formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: buildTextFieldForNumber(
                                  context,
                                  'Quantity',
                                  validator: controller.validateNos,
                                  controller: controller.productCountController,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: buildTextFieldForNumber(
                                  context,
                                  'Price (₹)',
                                  controller: controller.productPriceController,
                                  validator: controller.validateNos,
                                ),
                              ),
                            ],
                          ),
                          Obx(
                            () => DropdownButtonFormField<String>(
                              initialValue: controller.quantityType.value,
                              dropdownColor: AppColor.surface,
                              style: GoogleFonts.poppins(color: AppColor.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Quantity Type',
                                labelStyle: TextStyle(color: AppColor.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[700]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(
                                  Icons.category,
                                  color: AppColor.primary,
                                ),
                                filled: true,
                                fillColor: AppColor.background,
                              ),
                              items: ['Nos', 'Meter'].map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(
                                    type,
                                    style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  controller.quantityType.value = value;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.formKey.currentState!.validate()) {
                            controller.addProduct();
                            Navigator.pop(context);
                          } else {
                            Get.snackbar(
                              'Oops!',
                              'Please fill all required fields correctly',
                              backgroundColor: AppColor.surface,
                              colorText: AppColor.primary,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Add Product',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildTextFieldForNumber(
    BuildContext context,
    String label, {
    TextEditingController? controller,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        keyboardType: TextInputType.number,
        controller: controller,
        validator: validator,
        textInputAction: textInputAction ?? TextInputAction.next,
        style: GoogleFonts.poppins(
          fontSize: MediaQuery.of(context).size.height * 0.016,
          color: AppColor.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColor.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.numbers_outlined,
            size: 20,
            color: AppColor.primary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: AppColor.background,
        ),
      ),
    );
  }

  Widget _buildDesktopTable(InventoryController controller, BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColor.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Name', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                Expanded(flex: 2, child: Text('Barcode', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                Expanded(flex: 2, child: Text('Quantity', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                Expanded(flex: 1, child: Text('Unit', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                Expanded(flex: 2, child: Text('Price (₹)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                Expanded(flex: 2, child: Text('Total (₹)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
                Expanded(flex: 1, child: Text('Actions', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 14))),
              ],
            ),
          ),
          ...controller.products.asMap().entries.map((entry) {
            int idx = entry.key;
            var product = entry.value;
            return Material(
              color: idx.isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.02),
              child: InkWell(
                hoverColor: AppColor.primary.withValues(alpha: 0.1),
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(product.name, style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary))),
                      Expanded(flex: 2, child: Text(product.productId, style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary))),
                      Expanded(flex: 2, child: Text(product.count.toString(), style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary))),
                      Expanded(flex: 1, child: Text(product.quantityType, style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary))),
                      Expanded(flex: 2, child: Text(product.price.toStringAsFixed(2), style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary))),
                      Expanded(flex: 2, child: Text(product.totalPrice.toStringAsFixed(2), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColor.primary))),
                      Expanded(
                        flex: 1, 
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.delete_outline, color: AppColor.error, size: 22),
                            onPressed: () {
                              Get.defaultDialog(
                                backgroundColor: AppColor.surface,
                                title: "Delete Product",
                                middleText: "Are you sure you want to delete this product?",
                                titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                                middleTextStyle: GoogleFonts.poppins(color: AppColor.textSecondary),
                                textCancel: "Cancel",
                                textConfirm: "Delete",
                                confirmTextColor: AppColor.textOnPrimary,
                                cancelTextColor: AppColor.textPrimary,
                                buttonColor: AppColor.error,
                                onConfirm: () {
                                  controller.removeProduct(product.id);
                                  Get.back();
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileList(InventoryController controller, BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.products.length,
      itemBuilder: (context, index) {
        final product = controller.products[index];
        return Card(
          color: AppColor.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[800]!),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_outline, color: AppColor.error, size: 24),
                      onPressed: () {
                        Get.defaultDialog(
                          backgroundColor: AppColor.surface,
                          title: "Delete Product",
                          middleText: "Are you sure you want to delete this product?",
                          titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                          middleTextStyle: GoogleFonts.poppins(color: AppColor.textSecondary),
                          textCancel: "Cancel",
                          textConfirm: "Delete",
                          confirmTextColor: AppColor.textOnPrimary,
                          cancelTextColor: AppColor.textPrimary,
                          buttonColor: AppColor.error,
                          onConfirm: () {
                            controller.removeProduct(product.id);
                            Get.back();
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Barcode: ${product.productId}",
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Qty", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                        Text("${product.count} ${product.quantityType}", style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Price", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                        Text("₹${product.price.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Total", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                        Text("₹${product.totalPrice.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.primary)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
