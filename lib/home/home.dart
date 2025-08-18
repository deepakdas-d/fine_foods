// ignore_for_file: unused_local_variable

import 'package:fine_foods/ADMIN/dashboard/dashboard.dart';
import 'package:fine_foods/SALES/billing/view/billing.dart';
import 'package:fine_foods/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Home extends StatelessWidget {
  Home({super.key});
  final PrinterController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFD700),
        title: Text("HOME"),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () => controller.connectPrinter(context),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Get.to(() => Dashboard());
                },
                child: Text("Admin"),
              ),
              SizedBox(width: screenWidth * 0.05),
              ElevatedButton(
                onPressed: () {
                  Get.to(() => BillingScreen());
                },
                child: Text("Sales"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
