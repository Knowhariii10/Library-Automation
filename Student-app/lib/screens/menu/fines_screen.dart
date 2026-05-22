import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/database_helper.dart';
import '../../services/sync_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/fine_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/animations.dart';
import '../../widgets/premium_card.dart';

class FinesScreen extends StatefulWidget {
  const FinesScreen({super.key});

  @override
  State<FinesScreen> createState() => _FinesScreenState();
}

class _FinesScreenState extends State<FinesScreen> {
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FineProvider>().loadFines();
    });
  }

  Future<void> _refreshData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final fineProvider = Provider.of<FineProvider>(context, listen: false);

    if (userProvider.isAuthenticated) {
      await _syncService.syncData(
        userProvider,
        bookProvider,
        fineProvider: fineProvider,
      );
      await fineProvider.loadFines();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<FineProvider>(
      builder: (context, fineProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.getBackground(context),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              'Fines & Payments',
              style: TextStyle(
                color: AppColors.getTextPrimary(theme.brightness),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.getBackground(context).withOpacity(0.9),
                    AppColors.getBackground(context).withOpacity(0.5),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: _refreshData,
              ),
            ],
          ),
          body: fineProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SafeArea(
                    // Using SafeArea because extendBodyBehindAppBar is true
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSummaryCards(
                                  context,
                                  fineProvider.totalPaid,
                                  fineProvider.totalPending,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Recent History',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getAccentColor(
                                      theme.brightness,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                        fineProvider.fines.isEmpty
                            ? SliverFillRemaining(
                                child: _buildEmptyState(context),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    return AppAnimations.staggeredList(
                                      position: index,
                                      child: _buildFineCard(
                                        context,
                                        fineProvider.fines[index],
                                      ),
                                    );
                                  }, childCount: fineProvider.fines.length),
                                ),
                              ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 120),
                        ), // Global Scroll Padding
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    double totalPaid,
    double totalPending,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'TOTAL PAID',
            '₹${totalPaid.toStringAsFixed(2)}',
            AppColors.success,
            Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            'PENDING',
            '₹${totalPending.toStringAsFixed(2)}',
            AppColors.error,
            Icons.pending_actions_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextSecondary(theme.brightness),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(
                theme.brightness,
              ).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: AppColors.getTextSecondary(
                theme.brightness,
              ).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transaction history',
            style: TextStyle(
              color: AppColors.getTextSecondary(theme.brightness),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFineCard(BuildContext context, Map<String, dynamic> fine) {
    final theme = Theme.of(context);
    final double amount = (fine['amount'] ?? 0.0).toDouble();
    final bool isPaid = fine['status'] == 'PAID';
    final String dateStr = fine['date'] ?? '';
    final String txnId = fine['transaction_id'] ?? 'N/A';
    final String message = fine['reason'] ?? 'Overdue Fine';

    DateTime? date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {}

    final statusColor = isPaid ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPaid
                          ? Icons.check_rounded
                          : Icons.priority_high_rounded,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fine['book_title'] ?? message,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.getTextPrimary(theme.brightness),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fine['author'] != null && fine['author'].isNotEmpty
                              ? 'by ${fine['author']}'
                              : 'ID: ${txnId.length > 12 ? txnId.substring(0, 12) + "..." : txnId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(theme.brightness),
                          ),
                        ),
                        if (fine['rfid'] != null && fine['rfid'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'RFID: ${fine['rfid']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getAccentColor(
                                  theme.brightness,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.getTextPrimary(theme.brightness),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isPaid ? 'PAID' : 'PENDING',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.getTextSecondary(theme.brightness),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date != null
                            ? DateFormat('dd MMM yyyy').format(date)
                            : dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextSecondary(theme.brightness),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (!isPaid)
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pay at counter',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
