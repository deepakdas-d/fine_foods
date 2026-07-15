import 'package:fine_foods/ADMIN/DiscountCards/discount_cards_controller.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:fine_foods/models/discount_card_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscountCardsView extends StatelessWidget {
  DiscountCardsView({super.key});

  final DiscountCardController controller = Get.put(DiscountCardController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2329),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2329),
        title: Text(
          'Discount Cards',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.cards.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColor.primary));
        }

        if (controller.cards.isEmpty) {
          return Center(
            child: Text(
              'No Discount Cards found',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.cards.length,
          itemBuilder: (context, index) {
            final card = controller.cards[index];
            return _buildCardItem(card);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColor.primary,
        onPressed: () => _showAddEditDialog(null),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildCardItem(DiscountCard card) {
    Color badgeColor;
    switch (card.tier.toLowerCase()) {
      case 'platinum':
        badgeColor = const Color(0xFFE5E4E2); // Platinum
        break;
      case 'gold':
        badgeColor = const Color(0xFFFFD700); // Gold
        break;
      case 'silver':
      default:
        badgeColor = const Color(0xFFC0C0C0); // Silver
        break;
    }

    return Card(
      color: const Color(0xFF2B3139),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: badgeColor.withValues(alpha: 0.2),
          child: Icon(Icons.star, color: badgeColor),
        ),
        title: Text(
          card.tier.toUpperCase(),
          style: GoogleFonts.poppins(
            color: badgeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${card.discountPercent}% Discount',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: card.active ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                card.active ? 'ACTIVE' : 'INACTIVE',
                style: GoogleFonts.poppins(
                  color: card.active ? Colors.green : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white54),
              onPressed: () => _showAddEditDialog(card),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _confirmDelete(card),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(DiscountCard? card) {
    if (card != null) {
      controller.tierController.value = card.tier;
      controller.discountPercentController.text = card.discountPercent.toString();
      controller.activeController.value = card.active;
    } else {
      controller.clearForm();
    }

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF2B3139),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card == null ? 'Add Discount Card' : 'Edit Discount Card',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() => DropdownButtonFormField<String>(
                      initialValue: controller.tierController.value,
                      decoration: _inputDecoration('Tier'),
                      dropdownColor: const Color(0xFF1E2329),
                      style: GoogleFonts.poppins(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'platinum', child: Text('Platinum')),
                        DropdownMenuItem(value: 'gold', child: Text('Gold')),
                        DropdownMenuItem(value: 'silver', child: Text('Silver')),
                      ],
                      onChanged: (value) {
                        if (value != null) controller.tierController.value = value;
                      },
                    )),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.discountPercentController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: _inputDecoration('Discount Percentage (%)'),
                  validator: controller.validateDiscount,
                ),
                const SizedBox(height: 16),
                Obx(() => SwitchListTile(
                      title: Text(
                        'Active',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                      value: controller.activeController.value,
                      onChanged: (value) => controller.activeController.value = value,
                      activeThumbColor: AppColor.primary,
                      contentPadding: EdgeInsets.zero,
                    )),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (controller.formKey.currentState!.validate()) {
                          if (card == null) {
                            controller.addCard();
                          } else {
                            controller.updateCard(card.id);
                          }
                          Get.back();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        card == null ? 'Add' : 'Save',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(DiscountCard card) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2B3139),
        title: Text(
          'Delete Discount Card',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete the ${card.tier.toUpperCase()} card?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.removeCard(card.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColor.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: const Color(0xFF1E2329),
    );
  }
}
