import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/user_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/login_required_widget.dart';
import '../../widgets/shimmer_loading.dart';
import '../../services/database_helper.dart';
import '../../services/sync_service.dart';
import '../../models/transaction.dart' as tx_model;
import '../../theme/app_colors.dart';
import '../../widgets/premium_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  Future<void> _refreshData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    if (userProvider.isAuthenticated) {
      await _syncService.syncData(userProvider, bookProvider);
      await txProvider.loadTransactions();
    }
  }

  void _showQrDialog(tx_model.Transaction tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Verification QR\n${tx.transactionId}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: jsonEncode(tx.qrPayload),
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 8),
              const Text(
                'Show this to the librarian',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, TransactionProvider>(
      builder: (context, userProvider, txProvider, child) {
        if (!userProvider.isStudent) {
          return Scaffold(
            appBar: AppBar(title: const Text('Transactions')),
            body: LoginRequiredWidget(
              message: userProvider.isAuthenticated
                  ? 'Guests cannot view transactions. Please login as a student.'
                  : 'Login to view your rental transactions and fines',
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          appBar: const PremiumAppBar(),
          body: txProvider.isLoading
              ? const TransactionListSkeleton()
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: _buildTransactionsList(txProvider.transactions),
                ),
        );
      },
    );
  }

  Widget _buildTransactionsList(List<tx_model.Transaction> transactions) {
    if (transactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 200,
            alignment: Alignment.center,
            child: _buildEmptyState('No transactions yet', Icons.history),
          ),
        ),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: transactions.length,
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 120, // Global Scroll Padding
      ),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isRental = tx.type == 'RENTAL';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(tx.status).withOpacity(0.1),
              child: Icon(
                isRental ? Icons.book : Icons.payment,
                color: _getStatusColor(tx.status),
                size: 20,
              ),
            ),
            title: Text(
              tx.transactionId.isNotEmpty
                  ? tx.transactionId
                  : tx.id.length >= 8
                  ? 'TXN-${tx.id.substring(0, 8)}'
                  : 'TXN-${tx.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.message, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(tx.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tx.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(tx.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tx.date.toString().split(' ')[0],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            trailing:
                ![
                  'RETURNED',
                  'COMPLETED',
                  'REJECTED',
                  'CANCELLED',
                ].contains(tx.status.toUpperCase())
                ? IconButton(
                    icon: const Icon(Icons.qr_code_2, color: Color(0xFF1A237E)),
                    onPressed: () => _showQrDialog(tx),
                  )
                : tx.amount > 0
                ? Text(
                    '₹${tx.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )
                : null,
            children: [
              if (tx.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...tx.items
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] ?? 'Unknown Book',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        if (item['rfid'] != null &&
                                            item['rfid'].toString().isNotEmpty)
                                          Text(
                                            'RFID: ${item['rfid']}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      if (tx.returnedAt != null) ...[
                        const Divider(),
                        Text(
                          'Returned: ${tx.returnedAt.toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ] else if (tx.dueDate != null) ...[
                        const Divider(),
                        Text(
                          'Due Date: ${tx.dueDate.toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'COMPLETED':
      case 'RETURNED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'REJECTED':
      case 'OVERDUE':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
