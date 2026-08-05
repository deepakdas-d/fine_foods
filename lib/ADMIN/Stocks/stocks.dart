import 'package:fine_foods/ADMIN/Stocks/stock_controller.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:fine_foods/ADMIN/widgets/shimmer_widgets.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class Stocks extends StatelessWidget {
  const Stocks({super.key});

  void _showRestockModal(
    BuildContext context,
    StockAvailabilityController controller,
    Product product,
  ) {
    final qtyController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isAddMode = ValueNotifier<bool>(true);
    final qtyChangeNotifier = ValueNotifier<int>(0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColor.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColor.primary.withValues(alpha: 0.3)),
          ),
          title: Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: isAddMode,
                builder: (context, addMode, _) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: addMode
                          ? AppColor.primary.withValues(alpha: 0.15)
                          : AppColor.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      addMode ? Icons.add_shopping_cart : Icons.remove_shopping_cart,
                      color: addMode ? AppColor.primary : AppColor.error,
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Adjustment',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColor.primary,
                      ),
                    ),
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColor.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode Toggle (Add vs Reduce)
                  ValueListenableBuilder<bool>(
                    valueListenable: isAddMode,
                    builder: (context, addMode, _) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColor.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  isAddMode.value = true;
                                  formKey.currentState?.validate();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: addMode
                                        ? AppColor.primary.withValues(alpha: 0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: addMode
                                        ? Border.all(color: AppColor.primary)
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_circle,
                                        size: 18,
                                        color: addMode
                                            ? AppColor.primary
                                            : AppColor.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Add Stock (+)',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: addMode
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: addMode
                                              ? AppColor.primary
                                              : AppColor.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  isAddMode.value = false;
                                  formKey.currentState?.validate();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !addMode
                                        ? AppColor.error.withValues(alpha: 0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: !addMode
                                        ? Border.all(color: AppColor.error)
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.remove_circle,
                                        size: 18,
                                        color: !addMode
                                            ? AppColor.error
                                            : AppColor.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Reduce Stock (-)',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: !addMode
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: !addMode
                                              ? AppColor.error
                                              : AppColor.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColor.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current In-Stock:',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        Text(
                          '${product.count} ${product.quantityType}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: product.count == 0
                                ? AppColor.error
                                : (product.count <= 5
                                    ? AppColor.warning
                                    : AppColor.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: isAddMode,
                    builder: (context, addMode, _) {
                      return TextFormField(
                        controller: qtyController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(color: AppColor.textPrimary),
                        decoration: InputDecoration(
                          labelText: addMode ? 'Quantity to Add' : 'Quantity to Reduce',
                          hintText: 'e.g. 5',
                          labelStyle: GoogleFonts.poppins(
                            color: AppColor.textSecondary,
                          ),
                          prefixIcon: Icon(
                            addMode ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            color: addMode ? AppColor.primary : AppColor.error,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: addMode ? Colors.grey[700]! : AppColor.error.withValues(alpha: 0.5),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: AppColor.background,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return addMode
                                ? 'Enter quantity to add'
                                : 'Enter quantity to reduce';
                          }
                          final n = int.tryParse(val.trim());
                          if (n == null || n <= 0) {
                            return 'Must be a positive whole number';
                          }
                          if (!addMode && n > product.count) {
                            return 'Cannot reduce more than current stock (${product.count})';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          final n = int.tryParse(val.trim()) ?? 0;
                          qtyChangeNotifier.value = n > 0 ? n : 0;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: Listenable.merge([isAddMode, qtyChangeNotifier]),
                    builder: (context, _) {
                      final addMode = isAddMode.value;
                      final enteredQty = qtyChangeNotifier.value;
                      final newTotal = addMode
                          ? (product.count + enteredQty)
                          : (product.count - enteredQty);
                      final isInvalid = newTotal < 0;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: addMode
                              ? AppColor.primary.withValues(alpha: 0.1)
                              : (isInvalid
                                  ? AppColor.error.withValues(alpha: 0.15)
                                  : AppColor.warning.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: addMode
                                ? AppColor.primary.withValues(alpha: 0.3)
                                : (isInvalid
                                    ? AppColor.error
                                    : AppColor.warning.withValues(alpha: 0.3)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'New Total Stock:',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            Text(
                              isInvalid
                                  ? 'Invalid (Below 0)'
                                  : '$newTotal ${product.quantityType}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isInvalid
                                    ? AppColor.error
                                    : (addMode
                                        ? AppColor.primary
                                        : AppColor.warning),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColor.textSecondary),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isAddMode,
              builder: (context, addMode, _) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: addMode ? AppColor.primary : AppColor.error,
                    foregroundColor: addMode ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final qty = int.parse(qtyController.text.trim());
                      final delta = addMode ? qty : -qty;
                      Navigator.pop(context);
                      await controller.adjustStock(product.id, delta);
                    }
                  },
                  child: Text(
                    addMode ? 'Add Stock' : 'Reduce Stock',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StockAvailabilityController());

    return Scaffold(
      backgroundColor: AppColor.background, // Dark Background
      appBar: AppBar(
        title: Text(
          'Stock Availability',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: AppColor.background,
          ),
        ),
        backgroundColor: AppColor.primary, // Yellow
        centerTitle: true,
        foregroundColor: AppColor.background,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColor.background,
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh Stock',
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.refreshProducts(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(color: AppColor.surface, width: 1),
          borderRadius: BorderRadius.circular(12),
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
                  Obx(
                    () {
                      final isCalculating =
                          controller.isCalculatingTotal.value ||
                          (controller.total.value == 0.0 &&
                              controller.isLoading.value);
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
                  SizedBox(
                    width: 300,
                    child: Obx(
                      () => TextField(
                        controller: controller.searchController,
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
                              : (controller.searchQuery.value.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      color: AppColor.textSecondary,
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        controller.searchController.clear();
                                        controller.onSearchChanged('');
                                      },
                                    )
                                  : null),
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
                child: Obx(
                  () {
                    final _ = controller.products.length;
                    controller.isFetchingNextPage.value;
                    controller.isSearching.value;

                    if (controller.isLoading.value &&
                        controller.products.isEmpty) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 900) {
                            return const ShimmerTableSkeleton();
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(
    StockAvailabilityController controller,
    BuildContext context,
  ) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Estimate table content width ~800, distribute remaining space across 7 gaps (8 columns)
    double spacing = (screenWidth - 800) / 7;
    if (spacing < 20) spacing = 20;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Consistent bottom padding
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
                showFirstLastButtons: true, // Re-enabled to show first page button in footer
                header: Text(
                  'Stock Availability',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColor.primary),
                    tooltip: 'Refresh',
                    onPressed: () => controller.refreshProducts(),
                  ),
                ],
                rowsPerPage: StockAvailabilityController.pageSize,
                availableRowsPerPage: const [
                  StockAvailabilityController.pageSize,
                ],
                onPageChanged: (firstRowIndex) {
                  if (controller.searchQuery.value.isEmpty &&
                      firstRowIndex + StockAvailabilityController.pageSize >=
                          controller.products.length &&
                      controller.hasMore.value) {
                    controller.loadProducts(isLoadMore: true);
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
                      'Total',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Action',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                ],
                source: StockDataSource(
                  context,
                  controller,
                  (c, p) => _showRestockModal(c, controller, p),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(
    StockAvailabilityController controller,
    BuildContext context,
  ) {
    return RefreshIndicator(
      color: AppColor.primary,
      backgroundColor: AppColor.surface,
      onRefresh: () => controller.refreshProducts(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!controller.isFetchingNextPage.value &&
              controller.hasMore.value &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
            controller.loadProducts(isLoadMore: true);
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
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

          Color borderColor = Colors.grey[800]!;
          Icon? statusIcon;
          if (product.count == 0) {
            borderColor = AppColor.error;
            statusIcon = const Icon(
              Icons.warning_amber_rounded,
              color: AppColor.error,
              size: 20,
            );
          } else if (product.count <= 5) {
            borderColor = AppColor.warning;
            statusIcon = const Icon(
              Icons.error_outline,
              color: AppColor.warning,
              size: 20,
            );
          }

          return Card(
            key: ValueKey(product.id),
            color: AppColor.surface,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: borderColor,
                width: product.count <= 5 ? 1.5 : 1.0,
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
                        child: Row(
                          children: [
                            if (statusIcon != null) ...[
                              statusIcon,
                              const SizedBox(width: 8),
                            ],
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
                          ],
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Adjust Stock',
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.greenAccent,
                          size: 22,
                        ),
                        onPressed: () {
                          _showRestockModal(context, controller, product);
                        },
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
                              color: product.count == 0
                                  ? AppColor.error
                                  : (product.count <= 5
                                      ? AppColor.warning
                                      : AppColor.textPrimary),
                              fontWeight: FontWeight.bold,
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
          );
        },
      ),
    ),
  );
}
}

class StockDataSource extends DataTableSource {
  final BuildContext context;
  final StockAvailabilityController controller;
  final Function(BuildContext, Product) onRestock;

  StockDataSource(this.context, this.controller, this.onRestock);

  @override
  DataRow? getRow(int index) {
    if (index >= controller.products.length) return null;
    final product = controller.products[index];
    final idx = index;

    Color? rowColor;
    Icon? statusIcon;
    if (product.count == 0) {
      rowColor = AppColor.error.withValues(alpha: 0.1);
      statusIcon = const Icon(
        Icons.warning_amber_rounded,
        color: AppColor.error,
        size: 20,
      );
    } else if (product.count <= 5) {
      rowColor = AppColor.warning.withValues(alpha: 0.1);
      statusIcon = const Icon(
        Icons.error_outline,
        color: AppColor.warning,
        size: 20,
      );
    }

    return DataRow.byIndex(
      index: index,
      color: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        return rowColor; // Apply row background color based on stock status
      }),
      cells: [
        DataCell(
          Text(
            '${idx + 1}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColor.textPrimary,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              if (statusIcon != null) ...[statusIcon, const SizedBox(width: 8)],
              Expanded(
                child: Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColor.textPrimary,
                    fontWeight: product.count <= 5
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            product.productId,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColor.textSecondary,
            ),
          ),
        ),
        DataCell(
          Text(
            product.count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: product.count <= 5
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: product.count == 0
                  ? AppColor.error
                  : (product.count <= 5
                      ? AppColor.warning
                      : AppColor.textPrimary),
            ),
          ),
        ),
        DataCell(
          Text(
            product.quantityType,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColor.textPrimary,
            ),
          ),
        ),
        DataCell(
          Text(
            product.price.toStringAsFixed(2),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColor.textPrimary,
            ),
          ),
        ),
        DataCell(
          Text(
            product.totalPrice.toStringAsFixed(2),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
        ),
        DataCell(
          IconButton(
            tooltip: 'Adjust Stock',
            icon: const Icon(
              Icons.add_shopping_cart,
              color: Colors.greenAccent,
              size: 20,
            ),
            onPressed: () {
              onRestock(context, product);
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate =>
      controller.searchQuery.value.isEmpty && controller.hasMore.value;

  @override
  int get rowCount =>
      controller.products.length +
      (controller.searchQuery.value.isEmpty && controller.hasMore.value
          ? 1
          : 0);

  @override
  int get selectedRowCount => 0;
}
