import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/book_provider.dart' as book_p;
import '../auth/auth_screen.dart';
import '../reviews/review_screen.dart';
import '../cart/cart_screen.dart';
import '../../services/sync_service.dart';
import '../../services/database_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_card.dart';

class BookDetailsScreen extends StatefulWidget {
  final book_p.Book book;
  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late book_p.Book _book;
  List<Map<String, dynamic>> _reviews = [];
  bool _loadingReviews = true;
  bool _isReserved = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _loadBookDetails();
    _loadReviews();
    _checkReservationStatus();
  }

  Future<void> _loadBookDetails() async {
    try {
      final localData = await DatabaseHelper.instance.getBookById(
        widget.book.id,
      );
      if (localData != null && mounted) {
        final localBook = book_p.Book.fromJson(localData);

        // Only overwrite if the local content seems valid or if we don't have location
        // This prevents overwriting a valid 'widget.book' with an empty/stale local DB entry (race condition)
        Map<String, dynamic> mergedLocation = _book.location;
        if (localBook.location['section']?.toString().isNotEmpty == true) {
          mergedLocation = localBook.location;
        }

        setState(() {
          // Keep the memory-passed location if the DB one is empty
          _book = localBook.copyWith(location: mergedLocation);
        });
        print(
          'DEBUG: Loaded book from cache. Title: ${_book.title}, Location: ${_book.location}',
        );
        _checkReservationStatus();
      }
    } catch (e) {
      print('DEBUG: Error loading book details from cache: $e');
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loadingReviews = true;
    });

    try {
      // Try to load from local database first
      final localReviews = await DatabaseHelper.instance.getReviewsForBook(
        widget.book.id,
      );

      if (localReviews.isNotEmpty && mounted) {
        setState(() {
          _reviews = localReviews;
          _loadingReviews = false;
        });
      }

      // Then fetch from API to get latest reviews
      final apiService = ApiService();
      final apiReviews = await apiService.getBookReviews(widget.book.id);

      if (apiReviews.isNotEmpty) {
        // Save to local database
        await DatabaseHelper.instance.saveReviews(
          apiReviews.map((r) => r as Map<String, dynamic>).toList(),
        );

        if (mounted) {
          setState(() {
            _reviews = apiReviews
                .map((r) => r as Map<String, dynamic>)
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading reviews: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingReviews = false;
        });
      }
    }
  }

  Future<void> _checkReservationStatus() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final reservations = await dbHelper.getReservations();
      final isBookReserved = reservations.any(
        (r) =>
            r['book_id'] == widget.book.id &&
            (r['status'] == 'ACTIVE' || r['status'] == 'RESERVED'),
      );
      if (mounted) {
        setState(() {
          _isReserved = isBookReserved;
        });
      }
    } catch (e) {
      print('DEBUG: Error checking reservation status: $e');
    }
  }

  Future<void> _handleReserve(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bookProvider = Provider.of<book_p.BookProvider>(
      context,
      listen: false,
    );

    if (!userProvider.isStudent) {
      _showLoginPrompt(
        context,
        userProvider.isAuthenticated
            ? 'Guests cannot reserve books. Please login as a student.'
            : 'Please login to reserve a book',
      );
      return;
    }

    // Show loading
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Processing reservation...')));

    try {
      bookProvider.logBookInterest(_book);
      final apiService = ApiService();
      final result = await apiService.reserveBook(
        userProvider.token!,
        _book.id,
      );

      if (!mounted) return;
      if (result != null && result['success'] == true) {
        // Trigger immediate sync to show in My Reservations
        await SyncService().syncData(userProvider, bookProvider);
        await _checkReservationStatus(); // Update local state
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Book reserved successfully! Check "My Reservations" for details.',
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result?['error'] ?? 'Reservation failed. Please try again.',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please check your connection.'),
        ),
      );
    }
  }

  Future<void> _showLoginPrompt(BuildContext context, String message) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );

    if (result == true && context.mounted) {
      // Successfully logged in, proceed with the action
      _handleReserve(context);
    }
  }

  Future<void> _handleRefresh() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bookProvider = Provider.of<book_p.BookProvider>(
      context,
      listen: false,
    );

    // Sync all data first
    await SyncService().syncData(userProvider, bookProvider);

    // Then reload local states
    await _loadBookDetails();
    await _loadReviews();
    await _checkReservationStatus();
  }

  Future<void> _navigateToReviewScreen() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (!userProvider.isAuthenticated) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );

      // If user cancelled login or login failed, return
      if (result != true || !mounted) return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          selectedBooks: [
            {'id': _book.id, 'title': _book.title},
          ],
          isReturn: false,
        ),
      ),
    );

    // If review was submitted successfully, reload reviews
    if (result == true && mounted) {
      _loadReviews();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.getBackground(context),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Book Details'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.getBackground(context).withOpacity(0.9),
                    AppColors.getBackground(context).withOpacity(0.0),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(
                    theme.brightness,
                  ).withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.getTextPrimary(theme.brightness),
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceColor(
                        theme.brightness,
                      ).withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none,
                      color: AppColors.getTextPrimary(theme.brightness),
                    ),
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.getAccentColor(theme.brightness),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header Image with Hero Animation
                  Stack(
                    children: [
                      Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceColor(theme.brightness),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: 'book_image_${_book.id}',
                          child: _book.imagePath.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(32),
                                    bottomRight: Radius.circular(32),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: ApiService.getImageUrl(
                                      _book.imagePath,
                                    ),
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.getAccentColor(
                                          theme.brightness,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.book,
                                      size: 80,
                                      color: AppColors.getTextSecondary(
                                        theme.brightness,
                                      ),
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.book,
                                  size: 80,
                                  color: AppColors.getTextSecondary(
                                    theme.brightness,
                                  ),
                                ),
                        ),
                      ),
                      // Gradient Overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 100,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.getBackground(
                                  context,
                                ).withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Author Section
                        Center(
                          child: Column(
                            children: [
                              Text(
                                _book.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getTextPrimary(
                                        theme.brightness,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'by ${_book.author}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.getTextSecondary(
                                        theme.brightness,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Metadata Chips
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_book.department.isNotEmpty)
                              _buildInfoChip(
                                context,
                                Icons.category_outlined,
                                _book.department,
                              ),
                            const SizedBox(width: 12),
                            _buildInfoChip(
                              context,
                              Icons.stairs_outlined,
                              _book.difficultyLevel,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // About / Status Section
                        PremiumCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Availability',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getTextPrimary(
                                        theme.brightness,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _book.availableCopies > 0
                                          ? AppColors.success.withOpacity(0.1)
                                          : AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _book.availableCopies > 0
                                          ? 'In Stock'
                                          : 'Out of Stock',
                                      style: TextStyle(
                                        color: _book.availableCopies > 0
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildStatusRow(
                                context,
                                'Available Copies',
                                '${_book.availableCopies}',
                                Icons.inventory_2_outlined,
                              ),
                              if (_book.location['section']
                                          ?.toString()
                                          .isNotEmpty ==
                                      true ||
                                  (_book.location['row'] != null &&
                                      _book.location['row'] != 0) ||
                                  (_book.location['column'] != null &&
                                      _book.location['column'] != 0)) ...[
                                const SizedBox(height: 12),
                                _buildStatusRow(
                                  context,
                                  'Shelf Location',
                                  'Sec: ${(_book.location['section']?.toString().isEmpty ?? true) ? "-" : _book.location['section']}, '
                                      'Row: ${(_book.location['row'] == null || _book.location['row'] == 0) ? "-" : _book.location['row']}, '
                                      'Col: ${(_book.location['column'] == null || _book.location['column'] == 0) ? "-" : _book.location['column']}',
                                  Icons.location_on_outlined,
                                ),
                              ],
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.getAccentColor(
                                              theme.brightness,
                                            ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CartScreen(),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.shopping_cart_checkout,
                                      ),
                                      label: const Text(
                                        'View Cart',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        side: BorderSide(
                                          color: AppColors.getAccentColor(
                                            theme.brightness,
                                          ),
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        foregroundColor:
                                            AppColors.getTextPrimary(
                                              theme.brightness,
                                            ),
                                      ),
                                      onPressed: _isReserved
                                          ? null // Disable or keep active? User said "reserved and filled", implying state change
                                          : () => _handleReserve(context),
                                      icon: Icon(
                                        _isReserved
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: AppColors.getAccentColor(
                                          theme.brightness,
                                        ),
                                      ),
                                      label: Text(
                                        _isReserved ? 'PreHold' : 'PreHold',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Reviews Sections
                        Text(
                          'Reviews & Ratings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(theme.brightness),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PremiumCard(
                          onTap: _navigateToReviewScreen,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_book.avgRating.toStringAsFixed(1)}/5.0',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.getTextPrimary(
                                            theme.brightness,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Based on ${_book.reviewCount} reviews',
                                        style: TextStyle(
                                          color: AppColors.getTextSecondary(
                                            theme.brightness,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.getAccentColor(
                                    theme.brightness,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: AppColors.getAccentColor(
                                        theme.brightness,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Write Review',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getAccentColor(
                                          theme.brightness,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reviews List
                        if (_loadingReviews)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_reviews.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No reviews yet. Be the first to review!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: _reviews
                                .map((review) => _buildReviewItem(review))
                                .toList(),
                          ),

                        const SizedBox(height: 80), // Global Scroll Padding
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final rating = review['rating'] ?? 0;
    final userName = review['user_name'] ?? 'Anonymous';
    final reviewText = review['review_text'] ?? '';
    final createdAt = _formatDate(review['created_at']);
    final theme = Theme.of(context);

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.getTextPrimary(theme.brightness),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          if (reviewText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reviewText,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextPrimary(theme.brightness),
              ),
            ),
          ],
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              createdAt,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.getTextSecondary(theme.brightness),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(theme.brightness),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorderColor(theme.brightness)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.getTextSecondary(theme.brightness),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getTextPrimary(theme.brightness),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.getBackground(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.getTextSecondary(theme.brightness),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextSecondary(theme.brightness),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(theme.brightness),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
