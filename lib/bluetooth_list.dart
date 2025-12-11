import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fine_foods/home/home_controller.dart';

class BluetoothList extends StatelessWidget {
  const BluetoothList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PrinterController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Bluetooth Printer'),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
      ),
      body: Obx(() {
        if (controller.isScanning.value) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text("Scanning for Bluetooth printers..."),
              ],
            ),
          );
        }

        if (controller.availablePrinters.isEmpty) {
          return const Center(child: Text("No printers found"));
        }

        return ListView.builder(
          itemCount: controller.availablePrinters.length,
          itemBuilder: (context, index) {
            final printer = controller.availablePrinters[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Obx(
                () => ListTile(
                  leading:
                      controller.isConnecting.value &&
                          controller.connectingAddress == printer.address
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print),
                  title: Text(printer.name),
                  subtitle: Text(printer.address),
                  trailing:
                      controller.selectedPrinter?.address == printer.address &&
                          controller.isConnected.value
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () async {
                    await controller.connectPrinter(printer);
                    if (controller.isConnected.value) Get.back();
                  },
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        onPressed: controller.startScan,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
