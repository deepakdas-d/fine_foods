import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'sales_growth_controller.dart';

class SalesGrowth extends StatelessWidget {
  const SalesGrowth({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesGrowthController());

    return Scaffold(
      appBar: AppBar(title: const Text("Sales Growth")),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.productSales.isEmpty) {
          return const Center(child: Text("No sales data available."));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateColor.resolveWith(
              (states) => Colors.blue.shade100,
            ),
            columns: const [
              DataColumn(
                label: Text(
                  "Product Name",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Total Quantity Sold",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Total Quantity",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Remaining Stock",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: controller.productSales.map((entry) {
              return DataRow(
                cells: [
                  DataCell(Text(entry.name)),
                  DataCell(Text(entry.soldQty.toString())),
                  DataCell(Text(entry.inventoryQty.toString())),
                  DataCell(
                    Text(
                      entry.remainingQty.toString(),
                      style: TextStyle(
                        color: entry.remainingQty < 10
                            ? Colors.red
                            : Colors.black,
                        fontWeight: entry.remainingQty < 10
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}
