import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import '../cart/cart_screen.dart';
import '../history/history_screen.dart';
import '../menu/menu_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/rental_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/fine_provider.dart';
import '../../services/sync_service.dart';
import '../book_details/book_details_screen.dart';
import '../../widgets/book_image.dart';
import '../../widgets/floating_bottom_nav.dart';
import '../../widgets/premium_search_bar.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/premium_card.dart';
import '../../theme/app_colors.dart';
import '../../utils/animations.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final rentalProvider = Provider.of<RentalProvider>(
        context,
        listen: false,
      );
      final txProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final resProvider = Provider.of<ReservationProvider>(
        context,
        listen: false,
      );
      final notifProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      final fineProvider = Provider.of<FineProvider>(context, listen: false);

      _syncService.startPeriodicSync(
        userProvider,
        bookProvider,
        rentalProvider: rentalProvider,
        txProvider: txProvider,
        resProvider: resProvider,
        notifProvider: notifProvider,
        fineProvider: fineProvider,
      );

      // Load books first, then initialize cart from local DB
      await bookProvider.loadBooks();
      await cartProvider.init(bookProvider.books);

      // Initialize recommendations
      if (userProvider.isAuthenticated) {
        await bookProvider.generateRecommendations(userProvider.user!);
      }

      // Listen for new notifications to show popups
      SyncService.notificationStream.listen((message) {
        if (mounted) {
          _showTopNotification(message);
        }
      });
    });
  }

  void _showTopNotification(String message) {
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => entry.remove(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  @override
  void dispose() {
    _syncService.stopPeriodicSync();
    super.dispose();
  }

  // New tab order: Home, Transaction (History), Profile, Cart, Menu
  final List<Widget> _screens = [
    const _HomeContent(),
    const HistoryScreen(), // Transaction
    const ProfileScreen(), // CENTER
    const CartScreen(),
    const MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        // Use new floating bottom navigation
        bottomNavigationBar: FloatingBottomNav(
          selectedIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
        extendBody: true, // Allow body to extend behind bottom nav
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).loadBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      appBar: const PremiumAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          final bookProvider = Provider.of<BookProvider>(
            context,
            listen: false,
          );
          final syncService = SyncService();
          await syncService.syncData(userProvider, bookProvider);
          await bookProvider.loadBooks(); // Re-load from SQLite after sync
          if (userProvider.isAuthenticated) {
            await bookProvider.generateRecommendations(userProvider.user!);
          }
        },
        child: SingleChildScrollView(
          // Add global bottom padding for floating nav
          padding: const EdgeInsets.only(bottom: 120),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Greeting Section
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final userName = userProvider.user?.name ?? 'Student';
                    return Text(
                      'Hello, $userName!',
                      style: Theme.of(context).textTheme.displayLarge,
                    );
                  },
                ),
              ),
              // Premium Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: PremiumSearchBar(
                  hintText: 'Search books, authors, subjects...',
                  onChanged: (value) {
                    Provider.of<BookProvider>(
                      context,
                      listen: false,
                    ).filterBooks(value);
                  },
                  onMicTap: null,
                  // onMicTap: () {
                  //   // Voice search functionality (placeholder)
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     const SnackBar(
                  //       content: Text('Voice search coming soon!'),
                  //       duration: Duration(seconds: 2),
                  //     ),
                  //   );
                  // },
                ),
              ),

              // Recommendations Section
              Consumer<BookProvider>(
                builder: (context, bookProvider, child) {
                  if (bookProvider.recommendations.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recommended for You',
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 20,
                              color: AppColors.getAccentColor(
                                Theme.of(context).brightness,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          scrollDirection: Axis.horizontal,
                          itemCount: bookProvider.recommendations.length,
                          itemBuilder: (context, index) {
                            final book = bookProvider.recommendations[index];
                            return Container(
                              width: 150,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: PremiumCard(
                                onTap: () {
                                  bookProvider.logBookInterest(book);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BookDetailsScreen(book: book),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Stack(
                                            children: [
                                              BookImage(
                                                imagePath: book.imagePath,
                                                localImagePath:
                                                    book.localImagePath,
                                              ),
                                              if (book.availableCopies == 0)
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.error
                                                          .withOpacity(0.9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Out of Stock',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        book.title,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        book.author,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.getTextSecondary(
                                            Theme.of(context).brightness,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Library Collection',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),

              // Book List
              Consumer<BookProvider>(
                builder: (context, bookProvider, child) {
                  if (bookProvider.isLoading) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ShimmerLoading.listTile(),
                      ),
                    );
                  }

                  if (bookProvider.books.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No books found')),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookProvider.books.length,
                    itemBuilder: (context, index) {
                      final book = bookProvider.books[index];
                      return PremiumCard(
                        onTap: () {
                          bookProvider.logBookInterest(book);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BookDetailsScreen(book: book),
                            ),
                          );
                        },
                        child: BookCard(
                          id: book.id,
                          title: book.title,
                          author: book.author,
                          availableCopies: book.availableCopies,
                          imagePath: book.imagePath,
                          localImagePath: book.localImagePath,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final String id;
  final String title;
  final String author;
  final int availableCopies;
  final String imagePath;
  final String localImagePath;

  const BookCard({
    super.key,
    required this.id,
    required this.title,
    required this.author,
    required this.availableCopies,
    required this.imagePath,
    this.localImagePath = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookImage(imagePath: imagePath, localImagePath: localImagePath),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 4),
                Text(
                  'by $author',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (availableCopies > 0
                                    ? AppColors.success
                                    : AppColors.error)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        availableCopies > 0
                            ? 'Available: $availableCopies copies'
                            : 'Out of Stock',
                        style: TextStyle(
                          color: availableCopies > 0
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              final isFavorite = cart.isInWishlist(id);
              return AppAnimations.favoriteHeart(
                isFavorite: isFavorite,
                activeColor: AppColors.favorite,
                onTap: () {
                  cart.toggleWishlist(id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite
                            ? 'Removed from wishlist'
                            : 'Added to wishlist',
                      ),
                      duration: AppTheme.snackBarDuration,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
