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
    return Obx(
      () => Scaffold(
        body: PageView(
          controller: pageController,
          onPageChanged: (index) {
            controller.currentIndex.value = index;
          },
          children: _pages,
        ),
        bottomNavigationBar: AnimatedNotchBottomBar(
          notchBottomBarController: NotchBottomBarController(
            index: controller.currentIndex.value,
          ),
          bottomBarItems: bottomBarItems,
          color: Colors.amber,
          notchColor: Colors.black,
          showLabel: true,
          showShadow: true,
          itemLabelStyle: const TextStyle(color: Colors.black, fontSize: 17),
          kIconSize: 24,
          kBottomRadius: 16,
          onTap: (index) {
            controller.currentIndex.value = index;
            pageController.jumpToPage(index);
          },
        ),
      ),
    );
  }
}
