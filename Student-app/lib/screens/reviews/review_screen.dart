import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_card.dart';
import '../../utils/animations.dart';

class ReviewScreen extends StatefulWidget {
  final List<Map<String, String>> selectedBooks;
  final bool isReturn;

  const ReviewScreen({
    super.key,
    required this.selectedBooks,
    this.isReturn = true,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(String userId) async {
    if (_rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a star rating',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (widget.selectedBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No book selected for review',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiService =
          ApiService(); // FIX: Instantiate directly, not via Provider
      final bookId = widget.selectedBooks[0]['id']!;
      final token = Provider.of<UserProvider>(context, listen: false).token;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final result = await apiService.submitReview(
        token,
        bookId,
        _rating.round(),
        _reviewController.text,
      );

      if (result == null || result['success'] != true) {
        throw Exception(result?['error'] ?? 'Failed to submit review');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Review submitted successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
        ),
      );

      if (!widget.isReturn) {
        Navigator.pop(context);
      } else {
        // Clear form if staying on screen for return flow
        setState(() {
          _rating = 0.0;
          _reviewController.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error submitting review: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showReturnQRCode(BuildContext context, String userId) {
    final List<String> bookIds = widget.selectedBooks
        .map((b) => b['id'] ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final Map<String, dynamic> qrData = {
      "purpose": "RETURNING",
      "user_id": userId,
      "book_ids": bookIds,
    };

    final String qrString = jsonEncode(qrData);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurfaceColor(theme.brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Return QR Code',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(theme.brightness),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Show this QR code to the librarian to complete your return.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondary(theme.brightness),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: qrString,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Returning ${widget.selectedBooks.length} book(s)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.getAccentColor(theme.brightness),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'DONE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.getAccentColor(theme.brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final userId = userProvider.user?.id ?? 'unknown_user';
        final String firstBookTitle = widget.selectedBooks.isNotEmpty
            ? (widget.selectedBooks[0]['title'] ?? 'Selected Book')
            : 'No Book Selected';

        return Scaffold(
          extendBody: true,
          backgroundColor: AppColors.getBackground(context),
          appBar: PremiumAppBar(
            title: widget.isReturn ? 'Review & Return' : 'Write a Review',
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isReturn)
                    AppAnimations.staggeredList(
                      position: 0,
                      child: PremiumCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.selectedBooks.length == 1)
                                Text(
                                  firstBookTitle,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getTextPrimary(
                                      theme.brightness,
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Returning ${widget.selectedBooks.length} Books:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextPrimary(
                                          theme.brightness,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ...widget.selectedBooks.map(
                                      (b) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.book_outlined,
                                              size: 16,
                                              color: AppColors.getAccentColor(
                                                theme.brightness,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                b['title'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color:
                                                      AppColors.getTextPrimary(
                                                        theme.brightness,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    AppAnimations.staggeredList(
                      position: 0,
                      child: Text(
                        firstBookTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(theme.brightness),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  AppAnimations.staggeredList(
                    position: 1,
                    child: Text(
                      'How was the book?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(theme.brightness),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppAnimations.staggeredList(
                    position: 2,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starRating = index + 1;
                          return AppAnimations.buttonTap(
                            onTap: () =>
                                setState(() => _rating = starRating.toDouble()),
                            child: Icon(
                              starRating <= _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 48,
                              color: starRating <= _rating
                                  ? AppColors.warning
                                  : AppColors.getTextSecondary(
                                      theme.brightness,
                                    ).withOpacity(0.3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  AppAnimations.staggeredList(
                    position: 3,
                    child: TextField(
                      controller: _reviewController,
                      maxLines: 5,
                      style: TextStyle(
                        color: AppColors.getTextPrimary(theme.brightness),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts...',
                        hintStyle: TextStyle(
                          color: AppColors.getTextSecondary(theme.brightness),
                        ),
                        filled: true,
                        fillColor: AppColors.getSurfaceColor(theme.brightness),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.getBorderColor(theme.brightness),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.getBorderColor(theme.brightness),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.getAccentColor(theme.brightness),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  AppAnimations.staggeredList(
                    position: 4,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInfoField(
                            context,
                            'Department',
                            userProvider.user?.department ?? 'N/A',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoField(
                            context,
                            'Year',
                            userProvider.user?.year ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  AppAnimations.staggeredList(
                    position: 5,
                    child: AppAnimations.buttonTap(
                      onTap: _isSubmitting
                          ? () {}
                          : () => _submitReview(userId), // No-op if loading
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.getAccentColor(theme.brightness),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.getAccentColor(
                                theme.brightness,
                              ).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'SUBMIT REVIEW',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (widget.isReturn)
                    AppAnimations.staggeredList(
                      position: 6,
                      child: AppAnimations.buttonTap(
                        onTap: () => _showReturnQRCode(context, userId),
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.getTextPrimary(theme.brightness),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'PROCEED TO RETURN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: AppColors.getTextPrimary(theme.brightness),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoField(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.getTextSecondary(theme.brightness),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(theme.brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getBorderColor(theme.brightness),
              width: 0.5,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(theme.brightness),
            ),
          ),
        ),
      ],
    );
  }
}
