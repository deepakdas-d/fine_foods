import 'package:fine_foods/invoice_generator/controller/invoice_controller.dart';
import 'package:fine_foods/invoice_generator/view/invoice_generator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class InvoiceList extends StatelessWidget {
  InvoiceList({super.key});
  final InvoiceController controller = Get.put(InvoiceController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('invoices')
            .orderBy(
              'createdAt',
              descending: true,
            ) // Order by date, newest first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Trigger rebuild
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final invoices = snapshot.data!.docs;

          if (invoices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No invoices found.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your invoices will appear here once you create them.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              final data = invoice.data() as Map<String, dynamic>;

              // Parse and format date
              String formattedDate = '';
              if (data['createdAt'] != null) {
                try {
                  if (data['createdAt'] is Timestamp) {
                    final date = (data['createdAt'] as Timestamp).toDate();
                    formattedDate = DateFormat('MMM dd, yyyy').format(date);
                  } else if (data['createdAt'] is String) {
                    final date = DateTime.parse(data['createdAt']);
                    formattedDate = DateFormat('MMM dd, yyyy').format(date);
                  }
                } catch (e) {
                  formattedDate = data['createdAt'].toString();
                }
              }

              // Format amount
              final totalAmount = data['totalAmount']?.toString() ?? '0';
              final formattedAmount = NumberFormat(
                '#,##0.00',
              ).format(double.tryParse(totalAmount) ?? 0);

              return Card(
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.receipt, color: Colors.white),
                  ),
                  title: Text(
                    data['invoiceNumber'] ?? 'No Invoice Number',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "₹$formattedAmount",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (data['customerName'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          data['customerName'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  onTap: () => controller.handleInvoiceTap(context),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => InvoiceGenerator());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
