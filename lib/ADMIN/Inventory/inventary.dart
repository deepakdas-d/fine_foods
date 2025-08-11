import 'package:fine_foods/ADMIN/Inventory/inventory_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class Inventory extends StatelessWidget {
  const Inventory({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryController());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory Management',
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
            : Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Total Value: ₹${controller.total.value.toStringAsFixed(2)}',
                            style: GoogleFonts.k2d(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 25,
                            dataRowMaxHeight: 66,
                            headingRowHeight: 66,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            columns: [
                              DataColumn(
                                label: Text(
                                  'Name',
                                  style: GoogleFonts.k2d(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Barcode',
                                  style: GoogleFonts.k2d(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Quantity',
                                    style: GoogleFonts.k2d(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Unit',
                                    style: GoogleFonts.k2d(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Price (₹)',
                                    style: GoogleFonts.k2d(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Total',
                                    style: GoogleFonts.k2d(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Actions',
                                    style: GoogleFonts.k2d(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            rows: controller.products.map((product) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        product.name,
                                        style: GoogleFonts.k2d(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        product.productId,
                                        style: GoogleFonts.k2d(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        product.count.toString(),
                                        style: GoogleFonts.k2d(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        product.quantityType,
                                        style: GoogleFonts.k2d(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        product.price.toStringAsFixed(2),
                                        style: GoogleFonts.k2d(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        product.totalPrice.toStringAsFixed(2),
                                        style: GoogleFonts.k2d(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          Get.defaultDialog(
                                            title: "Delete Product",
                                            middleText:
                                                "Are you sure you want to delete this product?",
                                            titleStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            middleTextStyle: const TextStyle(
                                              color: Colors.black87,
                                            ),
                                            textCancel: "Cancel",
                                            textConfirm: "Delete",
                                            confirmTextColor: Colors.white,
                                            buttonColor: Colors.red,
                                            onConfirm: () {
                                              controller.removeProduct(
                                                product.id,
                                              );
                                              Get.back();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductModal(context, controller),
        backgroundColor: const Color(0xFFFFD700),
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
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
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(
                      'Add Product',
                      style: GoogleFonts.k2d(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.productNameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.shopping_bag,
                          color: Color(0xFFFFD700),
                        ),
                        filled: true,
                        fillColor: Colors.blue[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.productIdController,
                      decoration: InputDecoration(
                        labelText: 'Product Barcode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.qr_code,
                          color: Color(0xFFFFD700),
                        ),
                        filled: true,
                        fillColor: Colors.blue[50],
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
                              value: controller.quantityType.value,
                              decoration: InputDecoration(
                                labelText: 'Quantity Type',
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
                              items: ['Nos', 'Meter'].map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(
                                    type,
                                    style: GoogleFonts.k2d(fontSize: 14),
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
                              backgroundColor: Colors.white,
                              colorText: const Color(0xFFFFD700),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Add Product',
                          style: GoogleFonts.k2d(
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
        style: GoogleFonts.k2d(
          fontSize: MediaQuery.of(context).size.height * 0.016,
          color: const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.k2d(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
          prefixIcon: const Icon(
            Icons.numbers_outlined,
            size: 20,
            color: Color(0xFFFFD700),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.blue[50],
        ),
      ),
    );
  }
}
