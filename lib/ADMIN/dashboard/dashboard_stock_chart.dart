import 'package:fine_foods/ADMIN/sales_data/sales_growth_controller.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardStockSection extends StatelessWidget {
  const DashboardStockSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesGrowthController());
    
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: AppColor.primary),
          ),
        );
      }
      
      final lowStockItems = controller.productSales.where((p) => p.remainingQty < 10).toList();
      final demandedProducts = controller.productSales.where((p) => p.soldQty > 0).toList();
      final topProducts = demandedProducts.take(5).toList();

      return Container(
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColor.textSecondary.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (topProducts.isNotEmpty) ...[
              _buildHeader('Top Sales Items', Icons.trending_up),
              const SizedBox(height: 16),
              ...topProducts.map((p) => _buildTopSalesListItem(p)),
            ],
            
            if (topProducts.isNotEmpty && lowStockItems.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Colors.white10),
              ),
              
            if (lowStockItems.isNotEmpty) ...[
              _buildHeader('Low Stock Alert', Icons.warning_amber_rounded, isAlert: true),
              const SizedBox(height: 16),
              ...lowStockItems.map((p) => _buildLowStockListItem(p)),
            ],

            if (topProducts.isEmpty && lowStockItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No data available',
                    style: GoogleFonts.poppins(color: AppColor.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(String title, IconData icon, {bool isAlert = false}) {
    final color = isAlert ? AppColor.error : AppColor.textPrimary;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTopSalesListItem(ProductSalesData product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: AppColor.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    color: AppColor.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Remaining: ${product.remainingQty}',
                  style: GoogleFonts.poppins(
                    color: AppColor.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${product.soldQty}',
            style: GoogleFonts.poppins(
              color: AppColor.success,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockListItem(ProductSalesData product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColor.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_rounded, color: AppColor.error, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    color: AppColor.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Needs restock',
                  style: GoogleFonts.poppins(
                    color: AppColor.error.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${product.remainingQty} Left',
            style: GoogleFonts.poppins(
              color: AppColor.error,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
