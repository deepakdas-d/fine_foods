import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:fine_foods/bottom_navigation_controller.dart';
import 'package:fine_foods/login.dart';
import 'package:flutter/material.dart';
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
      inActiveItem: Icon(Icons.dashboard, color: Colors.grey),
      activeItem: Icon(Icons.dashboard, color: Colors.white),
      itemLabel: 'Admin',
    ),
    BottomBarItem(
      inActiveItem: Icon(Icons.home, color: Colors.grey),
      activeItem: Icon(Icons.home, color: Colors.white),
      itemLabel: 'Home',
    ),
    BottomBarItem(
      inActiveItem: Icon(Icons.point_of_sale, color: Colors.grey),
      activeItem: Icon(Icons.point_of_sale, color: Colors.white),
      itemLabel: 'Sales',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / bottomBarItems.length;

    return Obx(
      () => WillPopScope(
        onWillPop: () async {
          bool close =
              await Get.dialog(
                AlertDialog(
                  title: const Text('Confirm Exit'),
                  content: const Text('Do you want to exit the app?'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              ) ??
              false;
          return close;
        },
        child: Scaffold(
          body: PageView(
            controller: pageController,
            onPageChanged: (index) => controller.currentIndex.value = index,
            children: _pages,
          ),
          bottomNavigationBar: Container(
            color: Colors.amber,
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
                      color: isActive ? Colors.black : Colors.amber,
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
                            color: isActive ? Colors.white : Colors.black,
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
