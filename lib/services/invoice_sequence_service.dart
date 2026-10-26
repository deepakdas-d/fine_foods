import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationResult {
  final int totalMigrated;
  final String lastInvoiceNumber;
  final bool success;
  final String? errorMessage;

  MigrationResult({
    required this.totalMigrated,
    required this.lastInvoiceNumber,
    required this.success,
    this.errorMessage,
  });
}

class InvoiceSequenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _counterCollection = 'counters';
  static const String _counterDoc = 'invoices';
  static const int defaultDigits = 5;
  static const String defaultPrefix = 'INV-';

  /// Atomically increments the invoice counter in Firestore and returns the next formatted invoice number.
  /// Example: 'INV-00001'
  static Future<String> getNextInvoiceNumber({
    int digits = defaultDigits,
    String prefix = defaultPrefix,
  }) async {
    final counterRef = _firestore.collection(_counterCollection).doc(_counterDoc);
    developer.log('[InvoiceSequenceService] 1. Requesting atomic invoice sequence allocation...');

    try {
      final nextNumber = await _firestore.runTransaction<int>((transaction) async {
        final snapshot = await transaction.get(counterRef);
        int currentNumber = 0;

        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          currentNumber = (data['lastNumber'] as num?)?.toInt() ?? 0;
          developer.log('[InvoiceSequenceService] 2. Found existing counter: $currentNumber');
        } else {
          developer.log('[InvoiceSequenceService] 2. Counter document not found. Looking up highest bill...');
          try {
            final recentBills = await _firestore
                .collection('bills')
                .orderBy('createdAt', descending: true)
                .limit(20)
                .get();
            for (var doc in recentBills.docs) {
              final inv = doc.data()['invoiceNumber']?.toString() ?? '';
              if (inv.startsWith(prefix)) {
                final numPart = inv.substring(prefix.length);
                final parsed = int.tryParse(numPart);
                if (parsed != null && parsed > currentNumber) {
                  currentNumber = parsed;
                }
              }
            }
          } catch (e) {
            developer.log('[InvoiceSequenceService] Warning reading bills fallback: $e');
          }
        }

        final next = currentNumber + 1;
        developer.log('[InvoiceSequenceService] 3. Saving updated counter: $next');

        transaction.set(
          counterRef,
          {
            'lastNumber': next,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        return next;
      });

      final formatted = formatInvoiceNumber(nextNumber, digits: digits, prefix: prefix);
      developer.log('[InvoiceSequenceService] 4. Generated invoice number: $formatted');
      return formatted;
    } catch (e, s) {
      developer.log('[InvoiceSequenceService] Error in atomic transaction: $e\n$s', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Safely rolls back the counter if and only if the given invoice number was the last allocated number
  /// and no subsequent bill has claimed a higher sequence number.
  static Future<void> rollbackIfLast(String invoiceNumber, {String prefix = defaultPrefix}) async {
    try {
      if (!invoiceNumber.startsWith(prefix)) return;
      final numPart = invoiceNumber.substring(prefix.length);
      final allocatedNum = int.tryParse(numPart);
      if (allocatedNum == null || allocatedNum <= 0) return;

      final counterRef = _firestore.collection(_counterCollection).doc(_counterDoc);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(counterRef);
        if (snapshot.exists && snapshot.data() != null) {
          final current = (snapshot.data()!['lastNumber'] as num?)?.toInt() ?? 0;
          if (current == allocatedNum) {
            developer.log('[InvoiceSequenceService] Rolling back counter from $current to ${current - 1}');
            transaction.set(
              counterRef,
              {
                'lastNumber': current - 1,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }
        }
      });
    } catch (e) {
      developer.log('[InvoiceSequenceService] Rollback skipped / failed (non-critical): $e');
    }
  }

  /// Formats an integer into a sequential invoice string with padding.
  /// Example: formatInvoiceNumber(1) => 'INV-00001'
  static String formatInvoiceNumber(
    int number, {
    int digits = defaultDigits,
    String prefix = defaultPrefix,
  }) {
    return '$prefix${number.toString().padLeft(digits, '0')}';
  }

  /// Helper to safely parse createdAt from diverse Firestore formats.
  static DateTime parseCreatedAt(dynamic createdAt) {
    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }
    if (createdAt is String && createdAt.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Migrates all historical bills in Firestore into sequential 5-digit invoice numbers.
  /// 1. Fetches all bills from Firestore.
  /// 2. Sorts them chronologically (oldest -> newest).
  /// 3. Updates invoiceNumber to INV-00001, INV-00002, ...
  /// 4. Sets the central counter to the final sequence number so new bills seamlessly continue.
  static Future<MigrationResult> migrateHistoricalBills({
    void Function(int current, int total)? onProgress,
    int digits = defaultDigits,
    String prefix = defaultPrefix,
  }) async {
    try {
      developer.log('[InvoiceSequenceService] Starting historical bill migration...');
      final snapshot = await _firestore.collection('bills').get();

      if (snapshot.docs.isEmpty) {
        // No bills exist yet, initialize counter to 0
        await _firestore.collection(_counterCollection).doc(_counterDoc).set({
          'lastNumber': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return MigrationResult(
          totalMigrated: 0,
          lastInvoiceNumber: formatInvoiceNumber(0, digits: digits, prefix: prefix),
          success: true,
        );
      }

      // Sort documents chronologically
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aDate = parseCreatedAt(a.data()['createdAt']);
        final bDate = parseCreatedAt(b.data()['createdAt']);
        final dateComparison = aDate.compareTo(bDate);
        if (dateComparison != 0) return dateComparison;
        return a.id.compareTo(b.id);
      });

      final total = docs.length;
      developer.log('[InvoiceSequenceService] Found $total bills to re-index');

      // Process in batches (chunk size 400 to respect Firestore 500 operation limit)
      const chunkSize = 400;
      for (int i = 0; i < total; i += chunkSize) {
        final end = (i + chunkSize < total) ? i + chunkSize : total;
        final chunk = docs.sublist(i, end);
        final batch = _firestore.batch();

        for (int j = 0; j < chunk.length; j++) {
          final docIndex = i + j;
          final sequenceNumber = docIndex + 1;
          final newInvoiceNumber = formatInvoiceNumber(
            sequenceNumber,
            digits: digits,
            prefix: prefix,
          );

          batch.update(chunk[j].reference, {
            'invoiceNumber': newInvoiceNumber,
          });
        }

        await batch.commit();
        onProgress?.call(end, total);
        developer.log('[InvoiceSequenceService] Committed batch $end of $total');
      }

      // Update central counter to total
      await _firestore.collection(_counterCollection).doc(_counterDoc).set({
        'lastNumber': total,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final lastFormatted = formatInvoiceNumber(total, digits: digits, prefix: prefix);
      developer.log('[InvoiceSequenceService] Migration completed successfully. Total: $total, Last: $lastFormatted');

      return MigrationResult(
        totalMigrated: total,
        lastInvoiceNumber: lastFormatted,
        success: true,
      );
    } catch (e, s) {
      developer.log('[InvoiceSequenceService] Migration failed: $e\n$s');
      return MigrationResult(
        totalMigrated: 0,
        lastInvoiceNumber: '',
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}
