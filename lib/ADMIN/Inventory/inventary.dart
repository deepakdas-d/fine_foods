import 'package:fine_foods/ADMIN/Inventory/inventory_controller.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:fine_foods/ADMIN/widgets/shimmer_widgets.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class Inventory extends StatelessWidget {
  const Inventory({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryController());

    return Scaffold(
      backgroundColor: AppColor.background, // Dark Background
      appBar: AppBar(
        title: Obx(
          () => controller.isSelectionMode.value
              ? Text(
                  '${controller.selectedProducts.length} Selected',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: AppColor.background,
                  ),
                )
              : Text(
                  'Inventory Management',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: AppColor.background,
                  ),
                ),
        ),
        backgroundColor: AppColor.primary, // Yellow
        centerTitle: true,
        foregroundColor: AppColor.background,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        leading: Obx(() {
          if (controller.isSelectionMode.value) {
            return IconButton(
              icon: const Icon(Icons.close),
              onPressed: controller.toggleSelectionMode,
            );
          }
          final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
          final bool canPop = parentRoute?.canPop ?? false;
          return canPop ? const BackButton() : const SizedBox.shrink();
        }),
        actions: [
          Obx(
            () => controller.isSelectionMode.value
                ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColor.surface,
                          title: Text(
                            "Delete Selected Products",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          content: Text(
                            "Are you sure you want to delete ${controller.selectedProducts.length} products?",
                            style: GoogleFonts.poppins(
                              color: AppColor.textSecondary,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Cancel",
                                style: TextStyle(color: AppColor.textPrimary),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.error,
                              ),
                              onPressed: () {
                                controller.deleteSelectedProducts();
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Delete",
                                style: TextStyle(color: AppColor.textOnPrimary),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColor.surface,
            width: 1,
          ), // Darker border
          borderRadius: BorderRadius.circular(12),
          // Removed shadow for flat dark design
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 300,
                    child: Obx(
                      () => TextField(
                        onChanged: controller.onSearchChanged,
                        style: GoogleFonts.poppins(color: AppColor.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(color: AppColor.textSecondary),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColor.primary,
                          ),
                          suffixIcon: controller.isSearching.value
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: AppColor.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  // Register dependencies for Obx
                  controller.products.length;
                  controller.selectedProducts.length;
                  controller.isSelectionMode.value;
                  controller.isFetchingNextPage.value;
                  controller.isSearching.value;

                  if (controller.isLoading.value &&
                      controller.products.isEmpty) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 900) {
                          return const ShimmerTableSkeleton(columnCount: 8);
                        } else {
                          return const ShimmerCardList();
                        }
                      },
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 900) {
                        return _buildDesktopTable(controller, context);
                      } else {
                        return _buildMobileList(controller, context);
                      }
                    },
                  );
                }),
              ),
            ],
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
    InventoryController controller, {
    Product? product,
  }) {
    if (product != null) {
      controller.productNameController.text = product.name;
      controller.productIdController.text = product.productId;
      controller.productCountController.text = product.count.toString();
      controller.productPriceController.text = product.price.toString();
      controller.quantityType.value = product.quantityType;
      controller.cardDiscountExcluded.value = product.cardDiscountExcluded;
    } else {
      controller.clearForm();
      controller.generateUniqueBarcode();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product != null ? 'Edit Product' : 'Add Product',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColor.primary, // Yellow
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: AppColor.textSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
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
                                validator: controller.validatePrice,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        Obx(
                          () => DropdownButtonFormField<String>(
                            initialValue: controller.quantityType.value,
                            dropdownColor: AppColor.surface,
                            style: GoogleFonts.poppins(
                              color: AppColor.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Quantity Type',
                              labelStyle: TextStyle(
                                color: AppColor.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                ),
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
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColor.textPrimary,
                                  ),
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
                        const SizedBox(height: 12),
                        Obx(
                          () => SwitchListTile(
                            title: Text(
                              'Exclude from Card Discount (Low Margin)',
                              style: GoogleFonts.poppins(
                                color: AppColor.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            value: controller.cardDiscountExcluded.value,
                            onChanged: (val) =>
                                controller.cardDiscountExcluded.value = val,
                            activeThumbColor: AppColor.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[700]!),
                            foregroundColor: AppColor.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (controller.formKey.currentState!.validate()) {
                              if (product != null) {
                                controller.updateProduct(product.id);
                              } else {
                                controller.addProduct();
                              }
                              Navigator.pop(context);
                            } else {
                              controller.showToast(
                                'Please fill all required fields correctly',
                                Colors.red,
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
                            product != null ? 'Save Changes' : 'Add Product',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
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
    TextInputType keyboardType = TextInputType.number,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        keyboardType: keyboardType,
        controller: controller,
        validator: validator,
        textInputAction: textInputAction ?? TextInputAction.next,
        style: GoogleFonts.poppins(color: AppColor.textPrimary),
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

  Widget _buildDesktopTable(
    InventoryController controller,
    BuildContext context,
  ) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Estimate table content width ~800, distribute remaining space across 7 gaps
    double spacing = (screenWidth - 800) / 7;
    if (spacing < 20) spacing = 20;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Prevent FAB overlap
        child: SizedBox(
          width: double.infinity,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                cardColor: AppColor.surface,
                dividerColor: Colors.grey[800],
                textTheme: TextTheme(
                  bodyMedium: GoogleFonts.poppins(color: AppColor.textPrimary),
                  bodySmall: GoogleFonts.poppins(color: AppColor.textSecondary),
                ),
              ),
              child: PaginatedDataTable(
                key: controller.tableKey,
                columnSpacing: spacing,
                horizontalMargin: 32,
                showFirstLastButtons:
                    true, // Re-enabled to show first page button in footer
                header: Text(
                  'Products',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
                  ),
                ),
                rowsPerPage: InventoryController.pageSize,
                availableRowsPerPage: const [InventoryController.pageSize],
                onPageChanged: (firstRowIndex) {
                  if (controller.searchQuery.value.isEmpty &&
                      firstRowIndex + InventoryController.pageSize >=
                          controller.products.length &&
                      controller.hasMore.value) {
                    controller.loadInventory(isLoadMore: true);
                  }
                },
                columns: [
                  DataColumn(
                    label: Text(
                      'S.No',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Name',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Barcode',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Quantity',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Unit',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Price (₹)',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total (₹)',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                ],
                source: ProductDataSource(
                  context,
                  controller,
                  (c, p) => _showAddProductModal(c, controller, product: p),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(
    InventoryController controller,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Obx(
            () {
              final isCalculating = controller.total.value == 0.0 &&
                  (controller.isLoading.value || controller.isSearching.value);
              if (isCalculating) {
                return const ShimmerTotalValue();
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColor.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'Total Value: ₹${controller.total.value.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (!controller.isFetchingNextPage.value &&
                  controller.hasMore.value &&
                  scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent - 200) {
                controller.loadInventory(isLoadMore: true);
              }
              return false;
            },
            child: ListView.builder(
              itemCount:
                  controller.products.length +
                  (controller.isFetchingNextPage.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.products.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final product = controller.products[index];
                return Obx(() {
                  final isSelected = controller.selectedProducts.contains(
                    product.id,
                  );
                  final isSelectionMode = controller.isSelectionMode.value;

                  return GestureDetector(
                    onLongPress: () {
                      if (!isSelectionMode) {
                        controller.toggleSelectionMode();
                      }
                      controller.toggleProductSelection(product.id);
                    },
                    onTap: () {
                      if (isSelectionMode) {
                        controller.toggleProductSelection(product.id);
                      }
                    },
                    child: Card(
                      key: ValueKey(product.id),
                      color: isSelected ? Colors.grey[850] : AppColor.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? AppColor.primary
                              : Colors.grey[800]!,
                          width: isSelected ? 2 : 1,
                        ),
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
                                Row(
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: AppColor.primary,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        if (isSelectionMode) {
                                          controller.toggleProductSelection(
                                            product.id,
                                          );
                                        } else {
                                          _showAddProductModal(
                                            context,
                                            controller,
                                            product: product,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColor.error,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        if (isSelectionMode) {
                                          controller.toggleProductSelection(
                                            product.id,
                                          );
                                        } else {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: AppColor.surface,
                                              title: Text(
                                                "Delete Product",
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColor.textPrimary,
                                                ),
                                              ),
                                              content: Text(
                                                "Are you sure you want to delete this product?",
                                                style: GoogleFonts.poppins(
                                                  color: AppColor.textSecondary,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                      color:
                                                          AppColor.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            AppColor.error,
                                                      ),
                                                  onPressed: () {
                                                    controller.removeProduct(
                                                      product.id,
                                                    );
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                    "Delete",
                                                    style: TextStyle(
                                                      color: AppColor
                                                          .textOnPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Barcode: ${product.productId}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColor.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Qty",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColor.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      "${product.count} ${product.quantityType}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppColor.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Price",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColor.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      "₹${product.price.toStringAsFixed(2)}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppColor.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Total",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColor.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      "₹${product.totalPrice.toStringAsFixed(2)}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ProductDataSource extends DataTableSource {
  final BuildContext context;
  final InventoryController controller;
  final Function(BuildContext, Product) onEdit;

  ProductDataSource(this.context, this.controller, this.onEdit);

  void _toggleSelection(String productId) {
    controller.toggleProductSelection(productId);
    notifyListeners();
  }

  void _enterSelectionMode(String productId) {
    if (!controller.isSelectionMode.value) {
      controller.toggleSelectionMode();
    }
    controller.toggleProductSelection(productId);
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= controller.products.length) return null;
    final product = controller.products[index];
    final idx = index;

    final isSelected = controller.selectedProducts.contains(product.id);

    Widget wrapWithListener(Widget child) {
      return Listener(
        onPointerDown: (event) {
          if (event.buttons == 2) {
            _enterSelectionMode(product.id);
          }
        },
        child: InkWell(
          onTap: () {
            if (controller.isSelectionMode.value) {
              _toggleSelection(product.id);
            }
          },
          child: Container(
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.transparent,
            child: child,
          ),
        ),
      );
    }

    return DataRow.byIndex(
      index: index,
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (isSelected) return Colors.grey[850];
        return null;
      }),
      cells: [
        DataCell(
          wrapWithListener(
            Text(
              '${idx + 1}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColor.textPrimary,
              ),
            ),
          ),
        ),
        DataCell(
          wrapWithListener(
            Text(
              product.name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColor.textPrimary,
              ),
            ),
          ),
        ),
        DataCell(
          wrapWithListener(
            Text(
              product.productId,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColor.textPrimary,
              ),
            ),
          ),
        ),
        DataCell(
          wrapWithListener(
            Text(
              product.count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColor.textPrimary,
              ),
            ),
          ),
        ),
        DataCell(
          wrapWithListener(
            Text(
              product.quantityType,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColor.textPrimary,
              ),
            ),
          ),
        ),
        DataCell(
          wrapWithListener(
            Text(
              product.price.toStringAsFixed(2),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColor.textPrimary,
              ),
            ),
          ),
        ),
        DataCell(
          wrapWithListener(
            Text(
              product.totalPrice.toStringAsFixed(2),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColor.primary,
              ),
            ),
          ),
        ),
        DataCell(
          wrapWithListener(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColor.primary,
                    size: 22,
                  ),
                  onPressed: () {
                    if (controller.isSelectionMode.value) {
                      _toggleSelection(product.id);
                    } else {
                      onEdit(context, product);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColor.error,
                    size: 22,
                  ),
                  onPressed: () {
                    if (controller.isSelectionMode.value) {
                      _toggleSelection(product.id);
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColor.surface,
                          title: Text(
                            "Delete Product",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          content: Text(
                            "Are you sure you want to delete this product?",
                            style: GoogleFonts.poppins(
                              color: AppColor.textSecondary,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Cancel",
                                style: TextStyle(color: AppColor.textPrimary),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.error,
                              ),
                              onPressed: () {
                                controller.removeProduct(product.id);
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Delete",
                                style: TextStyle(color: AppColor.textOnPrimary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => controller.searchQuery.value.isEmpty && controller.hasMore.value;

  @override
  int get rowCount =>
      controller.products.length + (controller.searchQuery.value.isEmpty && controller.hasMore.value ? 1 : 0);

  @override
  int get selectedRowCount => 0;
}
