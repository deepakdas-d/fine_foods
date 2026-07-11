import 'package:fine_foods/appcolor.dart';
import 'package:fine_foods/home/bills_analytics_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class BillsAnalyticsWidget extends StatelessWidget {
  final bool isCompact;

  const BillsAnalyticsWidget({super.key, this.isCompact = false});

  String _formatCurrency(double value) {
    if (value >= 100000) {
      return 'Rs ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Rs ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<BillsAnalyticsController>();

    return Obx(() {
      if (c.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: AppColor.primary),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCards(c),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDonutChart(c)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildBarChart(c)),
                  ],
                );
              }
              return Column(
                children: [
                  _buildDonutChart(c),
                  const SizedBox(height: 16),
                  _buildBarChart(c),
                ],
              );
            },
          ),
        ],
      );
    });
  }

  Widget _buildStatCards(BillsAnalyticsController c) {
    final cards = [
      _StatData(Icons.receipt_long, 'Total Bills', '${c.totalBills.value}'),
      _StatData(
          Icons.currency_rupee, 'Total Sales', _formatCurrency(c.totalSales.value)),
      _StatData(Icons.money, 'Cash', _formatCurrency(c.totalCash.value)),
      _StatData(
          Icons.phone_android, 'Online', _formatCurrency(c.totalOnline.value)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards
          .map((data) => SizedBox(
                width: isCompact ? 150 : 170,
                child: _buildStatCard(data),
              ))
          .toList(),
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, color: AppColor.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: GoogleFonts.poppins(
              color: AppColor.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: GoogleFonts.poppins(
              color: AppColor.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(BillsAnalyticsController c) {
    final cash = c.totalCash.value;
    final online = c.totalOnline.value;
    final hasData = cash > 0 || online > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Cash vs Online',
            style: GoogleFonts.poppins(
              color: AppColor.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (!hasData)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No payment data',
                  style: GoogleFonts.poppins(
                    color: AppColor.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: [
                    PieChartSectionData(
                      value: cash,
                      color: const Color(0xFF4CAF50),
                      title: '${(cash / (cash + online) * 100).toStringAsFixed(0)}%',
                      titleStyle: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: online,
                      color: const Color(0xFF2196F3),
                      title: '${(online / (cash + online) * 100).toStringAsFixed(0)}%',
                      titleStyle: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      radius: 50,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(const Color(0xFF4CAF50), 'Cash'),
                const SizedBox(width: 20),
                _legendDot(const Color(0xFF2196F3), 'Online'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColor.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(BillsAnalyticsController c) {
    final quick = c.quickBillCount.value.toDouble();
    final inventory = c.inventoryCount.value.toDouble();
    final hasData = quick > 0 || inventory > 0;
    final maxY = hasData
        ? ([quick, inventory].reduce((a, b) => a > b ? a : b) * 1.3)
            .ceilToDouble()
        : 10.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Quick Bill vs Inventory',
            style: GoogleFonts.poppins(
              color: AppColor.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (!hasData)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'No bill data',
                  style: GoogleFonts.poppins(
                    color: AppColor.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(
                            color: AppColor.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final labels = ['Quick Bill', 'Inventory'];
                          if (value.toInt() < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                labels[value.toInt()],
                                style: GoogleFonts.poppins(
                                  color: AppColor.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(
                        toY: quick,
                        color: const Color(0xFFFCD535),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(
                        toY: inventory,
                        color: const Color(0xFF4CAF50),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;

  const _StatData(this.icon, this.label, this.value);
}
