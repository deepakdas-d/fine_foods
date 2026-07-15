import 'package:fine_foods/ADMIN/Customers/customer_controller.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:fine_foods/models/customer_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerView extends StatelessWidget {
  CustomerView({super.key});

  final CustomerController controller = Get.put(CustomerController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2329),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2329),
        title: Text(
          'Customers',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: controller.searchCustomers,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by Name or Phone',
                hintStyle: GoogleFonts.poppins(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2B3139),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.customers.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColor.primary));
        }

        if (controller.filteredCustomers.isEmpty) {
          return Center(
            child: Text(
              'No Customers found',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.filteredCustomers.length,
          itemBuilder: (context, index) {
            final customer = controller.filteredCustomers[index];
            return _buildCustomerItem(customer);
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

  Widget _buildCustomerItem(Customer customer) {
    Color badgeColor = Colors.grey;
    if (customer.cardTier != null) {
      switch (customer.cardTier!.toLowerCase()) {
        case 'platinum':
          badgeColor = const Color(0xFFE5E4E2);
          break;
        case 'gold':
          badgeColor = const Color(0xFFFFD700);
          break;
        case 'silver':
          badgeColor = const Color(0xFFC0C0C0);
          break;
      }
    }

    return Card(
      color: const Color(0xFF2B3139),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: badgeColor.withValues(alpha: 0.2),
          child: Icon(Icons.person, color: badgeColor),
        ),
        title: Text(
          customer.name,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.phone,
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            if (customer.cardTier != null)
              Text(
                'Tier: ${customer.cardTier!.toUpperCase()}',
                style: GoogleFonts.poppins(color: badgeColor, fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white54),
              onPressed: () => _showAddEditDialog(customer),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _confirmDelete(customer),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(Customer? customer) {
    if (customer != null) {
      controller.nameController.text = customer.name;
      controller.phoneController.text = customer.phone;
      controller.selectedCardId.value = customer.cardId;
    } else {
      controller.clearForm();
    }

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF2B3139),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: controller.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer == null ? 'Add Customer' : 'Edit Customer',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: controller.nameController,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: _inputDecoration('Name'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.phoneController,
                    style: GoogleFonts.poppins(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    decoration: _inputDecoration('Phone (10 digits)'),
                    validator: (value) =>
                        value == null || value.trim().length != 10 ? 'Enter 10 digit phone' : null,
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    return DropdownButtonFormField<String?>(
                      initialValue: controller.selectedCardId.value,
                      decoration: _inputDecoration('Discount Card (Optional)'),
                      dropdownColor: const Color(0xFF1E2329),
                      style: GoogleFonts.poppins(color: Colors.white),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No Card')),
                        ...controller.activeCards.map((card) {
                          return DropdownMenuItem(
                            value: card.id,
                            child: Text('${card.tier.toUpperCase()} (${card.discountPercent}%)'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        controller.selectedCardId.value = value;
                      },
                    );
                  }),
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
                            if (customer == null) {
                              controller.addCustomer();
                            } else {
                              controller.updateCustomer(customer.id);
                            }
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
                          customer == null ? 'Add' : 'Save',
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
      ),
    );
  }

  void _confirmDelete(Customer customer) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2B3139),
        title: Text(
          'Delete Customer',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${customer.name}?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.removeCustomer(customer.id);
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
      counterText: "",
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
