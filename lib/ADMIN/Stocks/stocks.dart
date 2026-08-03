import 'package:fine_foods/ADMIN/Stocks/stock_controller.dart';
import 'package:fine_foods/ADMIN/widgets/shimmer_widgets.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class Stocks extends StatelessWidget {
  const Stocks({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StockAvailabilityController());

    return Scaffold(
      backgroundColor: AppColor.background, // Dark Background
      appBar: AppBar(
        title: Text(
          'Stock Availability',
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
                          border: Border.all(color: AppColor.primary.withValues(alpha: 0.5)),
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
                        onChanged: controller.onSearchChanged,
                        style: GoogleFonts.poppins(color: AppColor.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(color: AppColor.textSecondary),
                          prefixIcon: const Icon(Icons.search, color: AppColor.primary),
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                    
                    if (controller.isLoading.value && controller.products.isEmpty) {
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

  Widget _buildDesktopTable(StockAvailabilityController controller, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Estimate table content width ~800, distribute remaining space across 6 gaps (7 columns)
    double spacing = (screenWidth - 800) / 6;
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
              header: Text('Stock Availability', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary)),
        rowsPerPage: StockAvailabilityController.pageSize,
        availableRowsPerPage: const [StockAvailabilityController.pageSize],
        onPageChanged: (firstRowIndex) {
          if (controller.searchQuery.value.isEmpty && firstRowIndex + StockAvailabilityController.pageSize >= controller.products.length && controller.hasMore.value) {
            controller.loadProducts(isLoadMore: true);
          }
        },
        columns: [
          DataColumn(label: Text('S.No', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary))),
          DataColumn(label: Text('Name', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary))),
          DataColumn(label: Text('Barcode', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary))),
          DataColumn(label: Text('Quantity', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary))),
          DataColumn(label: Text('Unit', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary))),
          DataColumn(label: Text('Price (₹)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary))),
          DataColumn(label: Text('Total', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColor.primary))),
        ],
        source: StockDataSource(context, controller),
      ),
    )))));
  }

  Widget _buildMobileList(StockAvailabilityController controller, BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!controller.isFetchingNextPage.value && 
            controller.hasMore.value && 
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          controller.loadProducts(isLoadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        itemCount: controller.products.length + (controller.isFetchingNextPage.value ? 1 : 0),
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
            statusIcon = const Icon(Icons.warning_amber_rounded, color: AppColor.error, size: 20);
          } else if (product.count <= 5) {
            borderColor = AppColor.warning;
            statusIcon = const Icon(Icons.error_outline, color: AppColor.warning, size: 20);
          }

          return Card(
            key: ValueKey(product.id),
            color: AppColor.surface,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: product.count <= 5 ? 1.5 : 1.0),
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
                            if (statusIcon != null) ...[statusIcon, const SizedBox(width: 8)],
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
                          Text(
                            "${product.count} ${product.quantityType}", 
                            style: GoogleFonts.poppins(
                              fontSize: 14, 
                              color: product.count == 0 ? AppColor.error : (product.count <= 5 ? AppColor.warning : AppColor.textPrimary), 
                              fontWeight: FontWeight.bold
                            ),
                          ),
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
      ),
    );
  }
}

class StockDataSource extends DataTableSource {
  final BuildContext context;
  final StockAvailabilityController controller;

  StockDataSource(this.context, this.controller);

  @override
  DataRow? getRow(int index) {
    if (index >= controller.products.length) return null;
    final product = controller.products[index];
    final idx = index;
    
    Color? rowColor;
    Icon? statusIcon;
    if (product.count == 0) {
      rowColor = AppColor.error.withValues(alpha: 0.1);
      statusIcon = const Icon(Icons.warning_amber_rounded, color: AppColor.error, size: 20);
    } else if (product.count <= 5) {
      rowColor = AppColor.warning.withValues(alpha: 0.1);
      statusIcon = const Icon(Icons.error_outline, color: AppColor.warning, size: 20);
    }

    return DataRow.byIndex(
      index: index,
      color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        return rowColor; // Apply row background color based on stock status
      }),
      cells: [
        DataCell(Text('${idx + 1}', style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary))),
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
                    fontWeight: product.count <= 5 ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(product.productId, style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textSecondary))),
        DataCell(Text(
          product.count.toString(), 
          style: GoogleFonts.poppins(
            fontSize: 14, 
            fontWeight: product.count <= 5 ? FontWeight.bold : FontWeight.normal,
            color: product.count == 0 ? AppColor.error : (product.count <= 5 ? AppColor.warning : AppColor.textPrimary),
          )
        )),
        DataCell(Text(product.quantityType, style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary))),
        DataCell(Text(product.price.toStringAsFixed(2), style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textPrimary))),
        DataCell(Text(product.totalPrice.toStringAsFixed(2), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColor.textPrimary))),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => controller.searchQuery.value.isEmpty && controller.hasMore.value;

  @override
  int get rowCount => controller.products.length + (controller.searchQuery.value.isEmpty && controller.hasMore.value ? 1 : 0);

  @override
  int get selectedRowCount => 0;
}
