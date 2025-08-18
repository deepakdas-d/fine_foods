// ignore_for_file: unused_local_variable

import 'package:fine_foods/ADMIN/dashboard/dashboard.dart';
import 'package:fine_foods/SALES/billing/view/billing.dart';
import 'package:fine_foods/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Home extends StatelessWidget {
  Home({super.key});
  final PrinterController controller = Get.find();

  // Local loader state
  final RxBool isLoading = false.obs;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        title: const Text("HOME"),
        foregroundColor: Colors.black,
        actions: [
          Obx(() {
            return IconButton(
              icon: Icon(
                controller.isConnected.value
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth,
                color: controller.isConnected.value ? Colors.green : null,
              ),
              tooltip: controller.isConnected.value
                  ? 'Printer Connected'
                  : 'Connect Printer',
              onPressed: () => controller.connectPrinter(context),
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(
                    () => ElevatedButton(
                      onPressed: isLoading.value
                          ? null // disable button while loading
                          : () async {
                              isLoading.value = true;
                              await Get.to(() => Dashboard());
                              isLoading.value = false;
                            },
                      child: const Text("Admin"),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.05),
                  Obx(
                    () => ElevatedButton(
                      onPressed: isLoading.value
                          ? null
                          : () async {
                              isLoading.value = true;
                              await Get.to(() => BillingScreen());
                              isLoading.value = false;
                            },
                      child: const Text("Sales"),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Loader overlay
          Obx(() {
            if (!isLoading.value) return const SizedBox.shrink();
            return Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            );
          }),
        ],
      ),
    );
  }
}
