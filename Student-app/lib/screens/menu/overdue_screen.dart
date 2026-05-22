import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_helper.dart';
import '../../widgets/book_image.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_card.dart';
import '../../utils/animations.dart';

class OverdueScreen extends StatefulWidget {
  const OverdueScreen({super.key});

  @override
  State<OverdueScreen> createState() => _OverdueScreenState();
}

class _OverdueScreenState extends State<OverdueScreen> {
  List<Map<String, dynamic>> _overdueBooks = [];
  Map<String, Map<String, dynamic>> _bookDetails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOverdueBooks();
  }

  Future<void> _loadOverdueBooks() async {
    final data = await DatabaseHelper.instance.getOverdueRentals();
    final Map<String, Map<String, dynamic>> details = {};

    for (var rental in data) {
      final bookId = rental['book_id'] as String?;
      if (bookId != null && !details.containsKey(bookId)) {
        final book = await DatabaseHelper.instance.getBookById(bookId);
        if (book != null) {
          details[bookId] = book;
        }
      }
    }

    if (mounted) {
      setState(() {
        _overdueBooks = data;
        _bookDetails = details;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadOverdueBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: const PremiumAppBar(),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.getAccentColor(Theme.of(context).brightness),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _overdueBooks.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 120, // Global Scroll Padding
                ),
                itemCount: _overdueBooks.length,
                itemBuilder: (context, index) {
                  return AppAnimations.staggeredList(
                    position: index,
                    child: _buildOverdueCard(_overdueBooks[index]),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
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
                Icons.check_circle_outline_rounded,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No overdue books',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(Theme.of(context).brightness),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Great job! You have returned all books on time.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.getTextSecondary(Theme.of(context).brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueCard(Map<String, dynamic> rental) {
    final bookId = rental['book_id'] as String?;
    final bookDetail = _bookDetails[bookId ?? ''];
    final String dueDateStr = rental['due_date'] ?? '';

    DateTime? dueDate;
    int daysOverdue = 0;
    try {
      dueDate = DateTime.parse(dueDateStr);
      daysOverdue = DateTime.now().difference(dueDate).inDays;
      if (daysOverdue < 0) daysOverdue = 0;
    } catch (_) {}

    final double fine = daysOverdue * 5.0; // Assume 5.0 per day fine

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookImage(
              imagePath: bookDetail?['image_path'] ?? '',
              localImagePath: bookDetail?['local_image_path'] ?? '',
              width: 70,
              height: 105,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rental['book_title'] ?? 'Unknown Book',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate) : dueDateStr}',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '$daysOverdue Days Late',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Fine: ₹${fine.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors
                                .orange[800], // Darker orange for readability
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
