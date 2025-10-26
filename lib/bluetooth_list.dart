import 'package:fine_foods/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BluetoothList extends StatelessWidget {
  const BluetoothList({super.key});

  @override
  Widget build(BuildContext context) {
    final printerController = Get.find<PrinterController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Bluetooth Printer'),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        actions: [
          Obx(
            () => printerController.isConnected.value
                ? IconButton(
                    icon: const Icon(Icons.bluetooth_disabled),
                    tooltip: 'Disconnect',
                    onPressed: printerController.disconnectPrinter,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (printerController.isScanning.value) {
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

        if (printerController.availablePrinters.isEmpty) {
          return const Center(child: Text("No printers found"));
        }

        return ListView.builder(
          itemCount: printerController.availablePrinters.length,
          itemBuilder: (context, index) {
            final printer = printerController.availablePrinters[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.print),
                title: Text(printer.name),
                subtitle: Text(printer.address),
                trailing: Obx(
                  () => printerController.printerName.value == (printer.name)
                      ? const Icon(Icons.check, color: Colors.green)
                      : const SizedBox.shrink(),
                ),
                onTap: () async {
                  await printerController.connectPrinter(printer);
                  if (printerController.isConnected.value) {
                    Get.back(); // return to previous page
                  }
                },
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        onPressed: () => printerController.startScan(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
