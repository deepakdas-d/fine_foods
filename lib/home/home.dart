// ignore_for_file: unused_local_variable

import 'package:fine_foods/billing/view/billing.dart';
import 'package:fine_foods/invoice_generator/view/invoice_generator.dart';
import 'package:fine_foods/invoice_view/invoice_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Home extends StatelessWidget {
  const Home({super.key});

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
            onPressed: () {
              Get.to(() => InvoiceList());
            },
            icon: Icon(Icons.inbox),
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
                  Get.to(() => InvoiceGenerator());
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
