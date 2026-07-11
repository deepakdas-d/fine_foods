import 'package:fine_foods/ADMIN/Bills/billing_list.dart';
import 'package:fine_foods/ADMIN/Bills/billing_list_controller.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserBills extends StatelessWidget {
  const UserBills({super.key});

  @override
  Widget build(BuildContext context) {
    // We register a separate controller for the user view so it doesn't
    // clash with the admin view's state if both are somehow alive.
    final tag = 'user_bills';
    if (!Get.isRegistered<BillListController>(tag: tag)) {
      Get.put(BillListController(), tag: tag);
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      // Minimal app bar for mobile (desktop sidebar shell handles its own navigation but this gives a nice header)
      appBar: AppBar(
        title: const Text('My Bills'),
        backgroundColor: AppColor.background,
        elevation: 0,
      ),
      body: BillingList(
        showSourceFilter: true, // We want the filter chips here
        showAdminActions: false, // No download all report button
        controllerTag: tag,
      ),
    );
  }
}
