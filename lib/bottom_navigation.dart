import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:fine_foods/bottom_navigation_controller.dart';
import 'package:fine_foods/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemNavigator
import 'package:get/get.dart';
import 'package:fine_foods/SALES/billing/view/billing.dart';
import 'package:fine_foods/home/home.dart';

class BottomNavPage extends StatelessWidget {
  BottomNavPage({super.key});

  final BottomNavController controller = Get.put(BottomNavController());

  final PageController pageController = PageController(initialPage: 1);

  final List<Widget> _pages = [LoginPage(), Home(), BillingScreen()];

  final List<BottomBarItem> bottomBarItems = const [
    BottomBarItem(
      inActiveItem: Icon(Icons.dashboard, color: AppColor.textSecondary),
      activeItem: Icon(Icons.dashboard, color: AppColor.primary),
      itemLabel: 'Admin',
    ),
    BottomBarItem(
      inActiveItem: Icon(Icons.home, color: AppColor.textSecondary),
      activeItem: Icon(Icons.home, color: AppColor.primary),
      itemLabel: 'Home',
    ),
    BottomBarItem(
      inActiveItem: Icon(Icons.point_of_sale, color: AppColor.textSecondary),
      activeItem: Icon(Icons.point_of_sale, color: AppColor.primary),
      itemLabel: 'Sales',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / bottomBarItems.length;

    return Obx(
      () => PopScope(
        canPop:
            false, // Prevent automatic pop (back button won't exit immediately)
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop)
            return; // Already popped (unlikely here due to canPop: false)

          // Show confirmation dialog
          final bool? shouldExit = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Confirm Exit'),
              content: const Text('Do you want to exit the app?'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false), // "No"
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () {
                    Get.closeCurrentSnackbar(); // Your previous workaround
                    Get.back(result: true); // "Yes"
                  },
                  child: const Text('Yes'),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            SystemNavigator.pop(); // Actually exit the app
          }
          // If false or null, do nothing (stay in app)
        },
        child: Scaffold(
          body: PageView(
            controller: pageController,
            onPageChanged: (index) => controller.currentIndex.value = index,
            children: _pages,
          ),
          bottomNavigationBar: Container(
            color: AppColor.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(bottomBarItems.length, (index) {
                final item = bottomBarItems[index];
                final isActive = controller.currentIndex.value == index;

                return GestureDetector(
                  onTap: () {
                    controller.currentIndex.value = index;
                    pageController.jumpToPage(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: itemWidth,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColor.textOnPrimary
                          : AppColor.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        isActive ? item.activeItem : item.inActiveItem,
                        const SizedBox(height: 4),
                        Text(
                          item.itemLabel ?? '',
                          style: TextStyle(
                            color: isActive
                                ? AppColor.primary
                                : AppColor.textOnPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
