import 'package:fine_foods/SALES/billing/controller/billing_controller.dart';
import 'package:fine_foods/ADMIN/Bills/billing_list_controller.dart';
import 'package:fine_foods/home/printer_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:fine_foods/appcolor.dart';
import 'package:printing/printing.dart';
import 'package:shimmer/shimmer.dart';

class BillingScreen extends StatelessWidget {
  final controller = Get.put(BillingController());
  final controllerlist = Get.put(BillListController());

  BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: _buildAppBar(context),
      body: Row(
        children: [
          _buildProductsArea(context),
          if (isLargeScreen) _buildCartSidebar(),
        ],
      ),
      floatingActionButton: !isLargeScreen ? _buildFAB(context) : null,
    );
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(
    elevation: 0,
    backgroundColor: AppColor.background,
    title: const Text(
      "Sales",
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColor.textPrimary,
      ),
    ),
    foregroundColor: AppColor.textPrimary,
    actions: [
      IconButton(
        onPressed: () => _showAddQuickItemDialog(context),
        icon: const Icon(
          Icons.flash_on,
          color: AppColor.primary,
        ),
        tooltip: 'Add Quick Item',
      ),
      Obx(
        () => Stack(
          children: [
            IconButton(
              onPressed: () => _showCartSheet(context),
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: AppColor.textPrimary,
              ),
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
                  child: Text(
                    '${controller.selectedProducts.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _buildProductsArea(BuildContext context) => Expanded(
    flex: 3,
    child: Column(
      children: [
        _buildSearchBar(context),
        Expanded(
          child: Obx(
            () {
              if (controller.isLoading.value || controller.isSearching.value) {
                return _buildShimmerGrid();
              }

              if (controller.filteredProducts.isEmpty) {
                final query = controller.searchQuery.value.trim();
                return RefreshIndicator(
                  onRefresh: () => controller.fetchProducts(refresh: true),
                  color: AppColor.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      const Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          query.isNotEmpty
                              ? 'No inventory products matching "$query"'
                              : 'No products found',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddQuickItemDialog(
                            context,
                            initialName: query,
                          ),
                          icon: const Icon(Icons.flash_on, size: 20),
                          label: Text(
                            query.isNotEmpty
                                ? 'Add "$query" as Quick Item'
                                : 'Add Quick / Custom Item',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchProducts(refresh: true),
                color: AppColor.primary,
                child: GridView.builder(
                  controller: controller.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 260,
                  ),
                  itemCount: controller.filteredProducts.length +
                      (controller.isFetchingMore.value ? 4 : 0),
                  itemBuilder: (context, index) {
                    if (index >= controller.filteredProducts.length) {
                      return _buildSkeletonCard();
                    }
                    return _buildProductCard(
                      controller.filteredProducts[index],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _buildShimmerGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 260,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Shimmer.fromColors(
      baseColor: AppColor.surface,
      highlightColor: Colors.grey[700]!,
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.textSecondary.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 16,
              width: 120,
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 16,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 24,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Obx(
              () => TextField(
                onChanged: controller.searchProducts,
                decoration: InputDecoration(
                  hintText: 'Search products by name or product ID...',
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
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showAddQuickItemDialog(
            context,
            initialName: controller.searchQuery.value.trim(),
          ),
          icon: const Icon(Icons.flash_on, size: 18),
          label: const Text('+ Quick Item'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildProductCard(Product product) => Obx(() {
    final isSelected = controller.getSelectedQuantity(product) > 0;
    final isOutOfStock = product.count <= 0;
    final quantity = controller.getSelectedQuantity(product);


    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColor.primary
              : AppColor.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isOutOfStock ? null : () => controller.increaseQuantity(product),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? Colors.grey.withValues(alpha: 0.3)
                      : AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 32,
                  color: isOutOfStock ? Colors.grey : AppColor.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isOutOfStock
                      ? AppColor.textSecondary
                      : AppColor.textPrimary,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '₹${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock
                            ? AppColor.textSecondary
                            : AppColor.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOutOfStock ? 'Out of Stock' : 'Stock: ${product.count}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOutOfStock ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!isOutOfStock)
                isSelected
                    ? Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                controller.decreaseQuantity(product),
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.red,
                          ),
                          Expanded(
                            child: Text(
                              '$quantity',
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
                            color: AppColor.primary,
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => controller.increaseQuantity(product),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  });

  Widget _buildCartSidebar() => Expanded(
    flex: 2,
    child: Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: _buildCartContent(),
    ),
  );

  Widget _buildCartContent() => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColor.primary),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white),
            const SizedBox(width: 12),
            const Text(
              'Shopping Cart',
              style: TextStyle(
                color: AppColor.textOnPrimary,
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
      Expanded(
        child: Obx(
          () => controller.selectedProducts.isEmpty
              ? const Center(
                  child: Text(
                    'Cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : Column(
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
                          final quantity =
                              controller.selectedProducts[productId]!;
                          return _buildCartItem(product, quantity);
                        },
                      ),
                    ),
                    _buildCheckoutSection(),
                  ],
                ),
        ),
      ),
    ],
  );

  Widget _buildCartItem(Product product, int quantity) {
    final isQuickItem = product.id.startsWith('custom_');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isQuickItem
              ? Colors.amber.withValues(alpha: 0.4)
              : AppColor.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isQuickItem
                  ? Colors.amber.withValues(alpha: 0.15)
                  : AppColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isQuickItem ? Icons.flash_on : Icons.inventory_2_outlined,
              color: isQuickItem ? Colors.amber[700] : AppColor.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                      ),
                    ),
                    if (isQuickItem)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Quick Item',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  '₹${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => controller.decreaseQuantity(product),
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red,
              ),
              Text(
                '$quantity',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => controller.increaseQuantity(product),
                icon: const Icon(Icons.add_circle_outline),
                color: AppColor.primary,
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '₹${(controller.getCustomPrice(product) * quantity).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColor.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    decoration: BoxDecoration(
      color: AppColor.background,
      border: Border(
        top: BorderSide(color: AppColor.textSecondary.withValues(alpha: 0.2)),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact Total Display First (Always Visible)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Obx(
                () => Text(
                  '₹${controller.calculateTotal().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Collapsible Advanced Options
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: const Text(
            'Payment & Details',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Obx(() {
            final type = controller.selectedPaymentType.value;
            final method = controller.paymentMethod.value;
            return Text(
              type == 'Split' ? 'Split Payment' : '$type • $method',
              style: TextStyle(fontSize: 14, color: AppColor.textSecondary),
            );
          }),
          children: [
            // Discount
            TextFormField(
              controller: controller.discountController,
              onChanged: (v) => controller.customerDiscount.value = v,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Discount (₹)',
                prefixIcon: const Icon(Icons.discount_outlined, size: 20),
                suffixIcon: controller.discountController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          controller.discountController.clear();
                          controller.customerDiscount.value = '';
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Customer Details (Compact Inline)
            Row(
              children: [
                Expanded(
                  child: Obx(() {
                    // Rebuild Autocomplete with a fresh key when cart is cleared
                    final key = controller.autocompleteKey.value;
                    return Autocomplete<Map<String, dynamic>>(
                      key: ValueKey(key),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.length < 3) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return controller.allCustomers.where((customer) {
                          final phone = customer['phone'] as String? ?? '';
                          return phone.contains(textEditingValue.text);
                        });
                      },
                      displayStringForOption: (option) => option['phone'] ?? '',
                      onSelected: (Map<String, dynamic> selection) {
                        controller.customerPhone.text = selection['phone'] ?? '';
                        controller.applySelectedCustomer(selection);
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        // Sync the Autocomplete's controller with the billing controller
                        controller.customerPhone = textEditingController;

                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone (Autocomplete)',
                            prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                  onPressed: () {
                                    textEditingController.clear();
                                    controller.applySelectedCustomer(null);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.search, size: 18, color: AppColor.primary),
                                  onPressed: () {
                                    controller.searchCustomerByPhone(textEditingController.text);
                                  },
                                ),
                              ],
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(8),
                            color: AppColor.surface,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option['phone'] ?? '', style: const TextStyle(color: AppColor.textPrimary)),
                                    subtitle: Text(option['name'] ?? '', style: const TextStyle(color: AppColor.textSecondary)),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.customerName,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Obx(() {
              if (controller.cardTierUsed.value != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${controller.cardTierUsed.value?.toUpperCase()} Card Applied: ${controller.cardDiscountPercent.value}%',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 16),

            // Payment Method & Type (Compact Cards)
            Obx(() {
              final isSplit = controller.selectedPaymentType.value == 'Split';
              return Column(
                children: [
                  // Payment Type
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Full', label: Text('Full')),
                      ButtonSegment(value: 'Split', label: Text('Split')),
                    ],
                    selected: {controller.selectedPaymentType.value},
                    onSelectionChanged: (set) {
                      final val = set.first;
                      controller.selectedPaymentType.value = val;
                      if (val == 'Full') {
                        controller.paymentMethod.value = 'Cash';
                        controller.cashReceived.value = controller
                            .calculateTotal()
                            .toStringAsFixed(2);
                        controller.onlineReceived.value = '0';
                      } else {
                        controller.cashReceived.value = '';
                        controller.onlineReceived.value = '';
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  if (!isSplit)
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Cash', label: Text('Cash')),
                        ButtonSegment(value: 'Online', label: Text('Online')),
                      ],
                      selected: {controller.paymentMethod.value},
                      onSelectionChanged: (set) =>
                          controller.paymentMethod.value = set.first,
                    ),

                  if (isSplit) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cash',
                              prefixIcon: const Icon(Icons.money, size: 18),
                              isDense: true,
                            ),
                            onChanged: (v) => controller.cashReceived.value = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Online',
                              prefixIcon: const Icon(Icons.qr_code, size: 18),
                              isDense: true,
                            ),
                            onChanged: (v) =>
                                controller.onlineReceived.value = v,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final cash =
                          double.tryParse(controller.cashReceived.value) ?? 0;
                      final online =
                          double.tryParse(controller.onlineReceived.value) ?? 0;
                      final total = controller.calculateTotal();
                      final received = cash + online;
                      return Text(
                        'Received: ₹${received.toStringAsFixed(2)} / ₹${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: received >= total
                              ? AppColor.success
                              : AppColor.error,
                        ),
                      );
                    }),
                  ],
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 12),

        // Generate Invoice Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.selectedProducts.isEmpty
                ? null
                : _generateInvoice,
            icon: const Icon(Icons.receipt_long),
            label: const Text(
              'Generate Invoice',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
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
  );

  Widget? _buildFAB(BuildContext context) => Obx(
    () => controller.selectedProducts.isNotEmpty
        ? FloatingActionButton.extended(
            onPressed: () => _showCartSheet(context),
            backgroundColor: AppColor.primary,
            icon: const Icon(Icons.shopping_cart, color: AppColor.background),
            label: Text(
              'Cart (${controller.selectedProducts.length})',
              style: TextStyle(color: AppColor.background),
            ),
          )
        : const SizedBox.shrink(),
  );

  void _showCartSheet(BuildContext context) => Get.bottomSheet(
    DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(child: _buildCartContent()),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );

  Future<void> _generateInvoice() async {
    developer.log('[GenerateInvoice] 1. Generate Invoice button clicked. Calling controller.createBill()...');
    print('[GenerateInvoice] 1. Generate Invoice button clicked. Calling controller.createBill()...');
    try {
      final billData = await controller.createBill();
      if (billData == null) {
        developer.log('[GenerateInvoice] createBill() returned null. Aborting.');
        print('[GenerateInvoice] createBill() returned null. Aborting.');
        return;
      }

      developer.log('[GenerateInvoice] 2. Bill created successfully. InvoiceNumber: ${billData['invoiceNumber']}');
      print('[GenerateInvoice] 2. Bill created successfully. InvoiceNumber: ${billData['invoiceNumber']}');

      developer.log('[GenerateInvoice] 3. Loading Roboto font from assets/fonts/Roboto-Regular.ttf...');
      print('[GenerateInvoice] 3. Loading Roboto font from assets/fonts/Roboto-Regular.ttf...');
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final robotoFont = pw.Font.ttf(fontData);

      developer.log('[GenerateInvoice] 4. Building PDF document and adding page...');
      print('[GenerateInvoice] 4. Building PDF document and adding page...');
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            80 * PdfPageFormat.mm,
            250 * PdfPageFormat.mm,
            marginAll: 5 * PdfPageFormat.mm,
          ),
          build: (context) {
            developer.log('[GenerateInvoice] 4a. Rendering PDF content callback...');
            return _buildPDFContent(billData, robotoFont);
          },
        ),
      );

      developer.log('[GenerateInvoice] 5. PDF page added. Opening dialog for Platform: ${Platform.operatingSystem}...');
      print('[GenerateInvoice] 5. PDF page added. Opening dialog for Platform: ${Platform.operatingSystem}...');

      // ================= WINDOWS =================
      if (Platform.isWindows) {
        developer.log('[GenerateInvoice] 6. Showing Windows preview dialog...');
        print('[GenerateInvoice] 6. Showing Windows preview dialog...');
        await Get.dialog(
          Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Invoice #${billData['invoiceNumber']} Preview',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PdfPreview(
                      build: (format) {
                        developer.log('[GenerateInvoice] 7. PdfPreview.build called. Saving PDF bytes...');
                        print('[GenerateInvoice] 7. PdfPreview.build called. Saving PDF bytes...');
                        return pdf.save();
                      },
                      allowPrinting: false,
                      allowSharing: false,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      initialPageFormat: const PdfPageFormat(
                        80 * PdfPageFormat.mm,
                        250 * PdfPageFormat.mm,
                        marginAll: 5 * PdfPageFormat.mm,
                      ),
                      actions: const [],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final printerController =
                                Get.find<PrinterController>();

                            if (kIsWeb) {
                              Get.snackbar(
                                'Web Mode',
                                'Not supported on Web',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            if (!printerController.isConnected.value) {
                              Get.snackbar(
                                'Error',
                                'No printer connected',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            try {
                              await controller.printInvoice(billData);
                              Get.snackbar(
                                'Success',
                                'Invoice printed successfully',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                              Get.back();
                            } catch (e) {
                              Get.snackbar(
                                'Error',
                                'Failed to print: $e',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                          child: const Text('Print'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      // ================= ANDROID =================
      else {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/invoice_${billData['invoiceNumber']}.pdf',
        );
        await file.writeAsBytes(await pdf.save());

        await Get.dialog(
          Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Invoice #${billData['invoiceNumber']} Preview',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: PDFView(filePath: file.path, enableSwipe: true),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final printerController =
                                Get.find<PrinterController>();

                            if (kIsWeb) {
                              Get.snackbar(
                                'Web Mode',
                                'Bluetooth printing not supported on Web',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            if (!printerController.isConnected.value) {
                              Get.snackbar(
                                'Error',
                                'No printer connected',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            try {
                              await controller.printInvoice(billData);
                              Get.snackbar(
                                'Success',
                                'Invoice printed successfully',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                              Get.back();
                            } catch (e) {
                              Get.snackbar(
                                'Error',
                                'Failed to print: $e',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                          child: const Text('Print'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await file.delete();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate preview: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  pw.Widget _buildPDFContent(
    Map<String, dynamic> billData,
    pw.Font robotoFont,
  ) {
    final subtotal = controllerlist.calculateBillSubtotal(billData);
    final discount = controllerlist.calculateBillDiscount(billData);
    final finalTotal = (subtotal - discount).clamp(0, double.infinity);

    final createdAt = DateTime.parse(billData['createdAt']).toLocal();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Invoice #${billData['invoiceNumber']}',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            font: robotoFont,
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Customer: ${billData['customerName']}',
          style: pw.TextStyle(font: robotoFont),
        ),
        if (billData['customerPhone'] != null &&
            billData['customerPhone'].toString().isNotEmpty)
          pw.Text(
            'Phone: ${billData['customerPhone']}',
            style: pw.TextStyle(font: robotoFont),
          ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Products:',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: robotoFont,
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(4), // Product name - wider
            1: const pw.FlexColumnWidth(1), // Qty
            2: const pw.FlexColumnWidth(2), // Price
            3: const pw.FlexColumnWidth(2), // Total
          },
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            // Header Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: ['Product', 'Qty', 'Price', 'Total']
                  .map(
                    (text) => pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        text,
                        style: pw.TextStyle(
                          font: robotoFont,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            // Product Rows - null-safe mapping
            ...((billData['products'] as List?) ?? []).map<pw.TableRow>(
              (product) {
                final p = (product is Map<String, dynamic>)
                    ? product
                    : <String, dynamic>{};
                final priceNum = (p['price'] as num?)?.toDouble() ?? 0.0;
                final totalNum = (p['total'] as num?)?.toDouble() ?? 0.0;
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        p['productName']?.toString() ?? '',
                        style: pw.TextStyle(font: robotoFont),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        p['quantity']?.toString() ?? '1',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: robotoFont),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Rs. ${priceNum.toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(font: robotoFont),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Rs. ${totalNum.toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          font: robotoFont,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Subtotal: Rs. ${subtotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: robotoFont),
                ),
                pw.Text(
                  'Discount: Rs. ${discount.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: robotoFont),
                ),
                pw.Text(
                  'Total: Rs. ${finalTotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: robotoFont,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Items: ${billData['itemCount']}',
          style: pw.TextStyle(font: robotoFont),
        ),
        pw.Text('Date: $formattedDate', style: pw.TextStyle(font: robotoFont)),
      ],
    );
  }

  void _showAddQuickItemDialog(BuildContext context, {String initialName = ''}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialName);
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final selectedType = 'unit'.obs;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flash_on, color: AppColor.primary, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Quick Item',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColor.textPrimary,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: initialName.isEmpty,
                  style: const TextStyle(color: AppColor.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g. Special Box, Custom Cake',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.label_outline),
                    isDense: true,
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Item name cannot be empty' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: AppColor.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Price (₹)',
                          hintText: '0.00',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                          isDense: true,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter price';
                          final price = double.tryParse(val.trim());
                          return price == null || price <= 0 ? 'Invalid price' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        style: const TextStyle(color: AppColor.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Qty',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter qty';
                          final qty = int.tryParse(val.trim());
                          return qty == null || qty <= 0 ? 'Invalid' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: selectedType.value,
                    dropdownColor: AppColor.surface,
                    style: const TextStyle(color: AppColor.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Unit / Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    items: ['unit', 'kg', 'pack', 'meter', 'box', 'piece']
                        .map(
                          (type) => DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) selectedType.value = val;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final name = nameController.text.trim();
                final price = double.parse(priceController.text.trim());
                final quantity = int.parse(quantityController.text.trim());
                controller.addQuickItem(
                  name: name,
                  price: price,
                  quantity: quantity,
                  quantityType: selectedType.value,
                );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
