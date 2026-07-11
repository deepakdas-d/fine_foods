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
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.grey[800],
                                dataTableTheme: DataTableThemeData(
                                  headingTextStyle: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.primary,
                                  ),
                                  dataTextStyle: GoogleFonts.poppins(
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                              ),
                              child: DataTable(
                                columnSpacing: 25,
                                dataRowMaxHeight: 66,
                                headingRowHeight: 66,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[800]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      'Name',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Barcode',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Quantity',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Unit',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Price (₹)',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Total',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Actions',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primary,
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
                                            style: GoogleFonts.poppins(
                                                fontSize: 14, color: AppColor.textPrimary),
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
                                            style: GoogleFonts.poppins(
                                                fontSize: 14, color: AppColor.textPrimary),
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
                                            style: GoogleFonts.poppins(
                                                fontSize: 14, color: AppColor.textPrimary),
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
                                            style: GoogleFonts.poppins(
                                                fontSize: 14, color: AppColor.textPrimary),
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
                                            style: GoogleFonts.poppins(
                                                fontSize: 14, color: AppColor.textPrimary),
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
                                            style: GoogleFonts.poppins(
                                                fontSize: 14, color: AppColor.textPrimary),
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
                                              color: AppColor.error, // Red
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              Get.defaultDialog(
                                                backgroundColor: AppColor.surface,
                                                title: "Delete Product",
                                                middleText:
                                                    "Are you sure you want to delete this product?",
                                                titleStyle: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColor.textPrimary,
                                                ),
                                                middleTextStyle: GoogleFonts.poppins(
                                                  color: AppColor.textSecondary,
                                                ),
                                                textCancel: "Cancel",
                                                textConfirm: "Delete",
                                                confirmTextColor: AppColor.textOnPrimary,
                                                cancelTextColor: AppColor.textPrimary,
                                                buttonColor: AppColor.error,
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
                              )),
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
}
