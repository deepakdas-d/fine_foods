import 'package:fine_foods/appcolor.dart';
import 'package:fine_foods/widgets/desktop_nav_controller.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fine_foods/ADMIN/Auth/auth_controller.dart';
import 'package:google_fonts/google_fonts.dart';

/// Data model for a single sidebar navigation item.
class _SidebarItem {
  final String label;
  final IconData icon;
  final int index;
  final bool isSection; // true = non-clickable section header

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.index,
    this.isSection = false,
  });
}

/// Persistent left sidebar for the desktop layout.
///
/// Shows grouped navigation items with section headers, hover effects,
/// active-state highlighting, and a branded app header.
class DesktopSidebar extends StatelessWidget {
  DesktopSidebar({super.key});

  final DesktopNavController controller = Get.find<DesktopNavController>();

  /// All sidebar navigation items, grouped by section.
  List<_SidebarItem> get _items {
    final auth = Get.find<AuthController>();
    final mainItems = [
      const _SidebarItem(
        label: 'MAIN',
        icon: Icons.more_horiz,
        index: -1,
        isSection: true,
      ),
      const _SidebarItem(label: 'Home', icon: Icons.home_rounded, index: 0),
      const _SidebarItem(label: 'Bills', icon: Icons.receipt_outlined, index: 8),
      const _SidebarItem(label: 'Sales Bill', icon: Icons.point_of_sale_rounded, index: 9),
    ];
    
    if (!kIsWeb) {
      mainItems.add(const _SidebarItem(
        label: 'Bluetooth / Printer',
        icon: Icons.bluetooth_rounded,
        index: 7,
      ));
    }

    if (auth.isAdminLoggedIn.value) {
      return [
        ...mainItems,
        const _SidebarItem(
          label: 'ADMIN',
          icon: Icons.more_horiz,
          index: -1,
          isSection: true,
        ),
        const _SidebarItem(label: 'Dashboard', icon: Icons.dashboard_rounded, index: 1),
        const _SidebarItem(label: 'Inventory', icon: Icons.inventory_2_rounded, index: 2),
        const _SidebarItem(label: 'Stocks', icon: Icons.store_rounded, index: 3),
        const _SidebarItem(label: 'Invoice Generator', icon: Icons.receipt_long_rounded, index: 4),
        const _SidebarItem(label: 'Sales Growth', icon: Icons.bar_chart_rounded, index: 5),
        const _SidebarItem(label: 'Bills', icon: Icons.receipt_outlined, index: 6),
      ];
    } else {
      return [
        ...mainItems,
        const _SidebarItem(
          label: 'ADMIN',
          icon: Icons.more_horiz,
          index: -1,
          isSection: true,
        ),
        const _SidebarItem(label: 'Admin Login', icon: Icons.login_rounded, index: 1),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = List<_SidebarItem>.from(_items);

      if (!kIsWeb && Get.find<AuthController>().isAdminLoggedIn.value) {
        items.add(
          const _SidebarItem(
            label: 'Bluetooth / Printer',
            icon: Icons.bluetooth_rounded,
            index: 7,
          ),
        );
      }

      return Container(
        width: 260,
        decoration: BoxDecoration(
          color: AppColor.surface,
          border: Border(
            right: BorderSide(
              color: AppColor.textSecondary.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: Column(
          children: [
            // ── App Brand Header ──
            _buildHeader(),
            const Divider(
              height: 1,
              color: Color(0xFF2F363E), // subtle separator
            ),

            // ── Navigation Items ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  if (item.isSection) {
                    return _buildSectionHeader(item.label);
                  }
                  return Obx(
                    () => _buildNavItem(
                      item,
                      isActive: controller.selectedIndex.value == item.index,
                    ),
                  );
                },
              ),
            ),

            // ── Footer ──
            _buildFooter(),
          ],
        ),
      );
    });
  }

  // ────────────────────────── Header ──────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          // App icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColor.textOnPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fine Foods',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Management System',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColor.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────── Section Header ──────────────────

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColor.textSecondary.withValues(alpha: 0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ────────────────────────── Nav Item ─────────────────────────

  Widget _buildNavItem(_SidebarItem item, {required bool isActive}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => controller.selectedIndex.value = item.index,
          hoverColor: AppColor.primary.withValues(alpha: 0.08),
          splashColor: AppColor.primary.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColor.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(
                      color: AppColor.primary.withValues(alpha: 0.25),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColor.primary.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: isActive ? AppColor.primary : AppColor.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                // Label
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColor.textPrimary
                          : AppColor.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Active indicator dot removed to reduce visual clutter
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────── Footer ──────────────────────────

  Widget _buildFooter() {
    final auth = Get.find<AuthController>();
    if (!auth.isAdminLoggedIn.value) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColor.textSecondary.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 18,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Admin',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColor.textPrimary,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => auth.logout(),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColor.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
