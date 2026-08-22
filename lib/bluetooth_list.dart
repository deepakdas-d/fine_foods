import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fine_foods/home/printer_controller.dart';
import 'package:fine_foods/appcolor.dart';

class BluetoothList extends StatelessWidget {
  const BluetoothList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PrinterController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select  Printer'),
        backgroundColor: AppColor.background,
        foregroundColor: AppColor.textPrimary,
        actions: [
          IconButton(
            onPressed: controller.disconnectPrinter,
            icon: Icon(
              Icons.bluetooth_disabled_outlined,
              color: AppColor.textPrimary,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isScanning.value) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColor.primary),
                SizedBox(height: 12),
                Text(
                  "Scanning for Bluetooth printers...",
                  style: TextStyle(color: AppColor.textPrimary),
                ),
              ],
            ),
          );
        }

        if (controller.availablePrinters.isEmpty) {
          return Center(
            child: Text(
              "No printers found",
              style: TextStyle(color: AppColor.textPrimary),
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.availablePrinters.length,
          itemBuilder: (context, index) {
            final printer = controller.availablePrinters[index];

            return Card(
              color: AppColor.surface,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Obx(
                () => Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading:
                        controller.isConnecting.value &&
                            controller.connectingAddress == printer.address
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColor.primary,
                            ),
                          )
                        : Icon(Icons.print, color: AppColor.textPrimary),
                    title: Text(
                      printer.name,
                      style: TextStyle(color: AppColor.textPrimary),
                    ),
                    subtitle: Text(
                      printer.address,
                      style: TextStyle(color: AppColor.textSecondary),
                    ),
                    trailing:
                        controller.selectedPrinter?.address ==
                                printer.address &&
                            controller.isConnected.value
                        ? Icon(Icons.check, color: AppColor.success)
                        : null,
                    onTap: () async {
                      await controller.connectPrinter(printer);
                      if (context.mounted &&
                          controller.isConnected.value &&
                          Navigator.of(context).canPop()) {
                        Get.back();
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColor.primary,
        foregroundColor: AppColor.textOnPrimary,
        onPressed: controller.startScan,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
