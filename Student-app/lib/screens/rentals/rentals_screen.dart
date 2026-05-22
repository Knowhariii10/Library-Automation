import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/rental_provider.dart';
import '../../services/database_helper.dart';
import '../../services/sync_service.dart';
import '../../widgets/book_image.dart';
import '../../widgets/login_required_widget.dart';
import '../reviews/review_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_card.dart';
import '../../utils/animations.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  Set<String> _selectedBookIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().loadRentals();
    });
  }

  Future<void> _refresh() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final rentalProvider = Provider.of<RentalProvider>(context, listen: false);
    await SyncService().syncData(userProvider, null);
    await rentalProvider.loadRentals();
  }

  Map<String, dynamic> _getOverdueInfo(String dueDateStr) {
    try {
      final dueDate = DateTime.parse(dueDateStr);
      final now = DateTime.now();

      if (now.isAfter(dueDate)) {
        final difference = now.difference(dueDate).inDays;
        final daysOverdue = difference > 0 ? difference : 0;
        final fine = daysOverdue * 5.0; // 5.0 per day
        return {
          'isOverdue': daysOverdue > 0,
          'daysOverdue': daysOverdue,
          'fine': fine,
        };
      }
    } catch (e) {
      debugPrint('Error parsing due date: $e');
    }
    return {'isOverdue': false, 'daysOverdue': 0, 'fine': 0.0};
  }

  void _toggleSelection(String bookId) {
    setState(() {
      if (_selectedBookIds.contains(bookId)) {
        _selectedBookIds.remove(bookId);
      } else {
        _selectedBookIds.add(bookId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, RentalProvider>(
      builder: (context, userProvider, rentalProvider, child) {
        if (!userProvider.isStudent) {
          return const Scaffold(
            appBar: PremiumAppBar(title: 'My Rentals'),
            body: LoginRequiredWidget(
              message: 'Check your current rented books and status.',
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          appBar: PremiumAppBar(
            title: 'My Rentals',
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: AppColors.getTextPrimary(Theme.of(context).brightness),
                ),
                onPressed: _refresh,
              ),
            ],
          ),
          body: rentalProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: rentalProvider.rentals.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 16,
                                  bottom: 120, // Global Scroll Padding
                                ),
                                itemCount: rentalProvider.rentals.length,
                                itemBuilder: (context, index) {
                                  return AppAnimations.staggeredList(
                                    position: index,
                                    child: _buildRentalCard(
                                      rentalProvider.rentals[index],
                                      rentalProvider.bookDetails,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: _selectedBookIds.isNotEmpty
              ? _buildFixedBottomButton(context, rentalProvider.rentals)
              : null,
        );
      },
    );
  }

  Widget _buildFixedBottomButton(
    BuildContext context,
    List<Map<String, dynamic>> rentals,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(theme.brightness),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: AppAnimations.buttonTap(
          onTap: () => _handleBulkReturn(rentals),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.getAccentColor(theme.brightness),
                  AppColors.getAccentColor(theme.brightness).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getAccentColor(
                    theme.brightness,
                  ).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'PROCEED TO RETURN (${_selectedBookIds.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.getTextPrimary(theme.brightness),
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.getSurfaceColor(
                      Theme.of(context).brightness,
                    ).withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: AppColors.getTextSecondary(
                      Theme.of(context).brightness,
                    ).withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No active rentals found',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AppAnimations.buttonTap(
                  onTap: _refresh,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getAccentColor(
                        Theme.of(context).brightness,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'REFRESH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(
    Map<String, dynamic> rental,
    Map<String, Map<String, dynamic>> bookDetails,
  ) {
    final bookId = rental['book_id'];
    final overdueInfo = _getOverdueInfo(rental['due_date']);
    final bool isOverdue = overdueInfo['isOverdue'];
    final double fine = overdueInfo['fine'];
    final isSelected = _selectedBookIds.contains(bookId);

    final bookDetail = bookDetails[bookId ?? ''];
    final String? imagePath = bookDetail?['image_path'];
    final theme = Theme.of(context);

    return PremiumCard(
      onTap: () => _toggleSelection(bookId ?? ''),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: isSelected,
                    activeColor: AppColors.getAccentColor(theme.brightness),
                    checkColor: AppColors.getTextPrimary(theme.brightness),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) => _toggleSelection(bookId ?? ''),
                  ),
                ),
                const SizedBox(width: 8),
                BookImage(
                  imagePath: imagePath ?? '',
                  localImagePath: bookDetail?['local_image_path'] ?? '',
                  width: 60,
                  height: 90,
                  iconSize: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental['book_title'] ?? 'Unknown Book',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceColor(
                            theme.brightness,
                          ).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.getBorderColor(theme.brightness),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'by ${bookDetail?['author'] ?? 'Unknown Author'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextSecondary(theme.brightness),
                          ),
                        ),
                      ),
                      if (rental['rfid'] != null &&
                          rental['rfid'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.info.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'RFID: ${rental['rfid']}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'OVERDUE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: isOverdue
                          ? AppColors.error
                          : AppColors.getTextSecondary(theme.brightness),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Due: ${_formatDate(rental['due_date'])}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isOverdue
                            ? AppColors.error
                            : AppColors.getTextPrimary(theme.brightness),
                      ),
                    ),
                  ],
                ),
                if (fine > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Fine: ₹${fine.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBulkReturn(List<Map<String, dynamic>> rentals) async {
    final selectedBooks = rentals
        .where((r) => _selectedBookIds.contains(r['book_id']))
        .map((r) => {'id': r['book_id'], 'title': r['book_title']})
        .toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          selectedBooks: selectedBooks
              .map((e) => Map<String, String>.from(e))
              .toList(),
        ),
      ),
    );

    if (mounted) {
      _refresh();
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonth(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
