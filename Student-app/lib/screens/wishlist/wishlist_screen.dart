import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/book_provider.dart';
import '../book_details/book_details_screen.dart';
import '../../widgets/book_image.dart';
import '../../theme/app_colors.dart';
import '../../utils/animations.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/premium_app_bar.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: const PremiumAppBar(),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          final bookProvider = Provider.of<BookProvider>(
            context,
            listen: false,
          );
          final wishlistIds = cart.wishlist;

          if (wishlistIds.isEmpty) {
            return _buildEmptyState(context);
          }

          final wishlistBooks = bookProvider.books
              .where((b) => wishlistIds.contains(b.id))
              .toList();

          return ListView.builder(
            itemCount: wishlistBooks.length,
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 120, // Global Scroll Padding
            ),
            itemBuilder: (context, index) {
              final book = wishlistBooks[index];
              return AppAnimations.staggeredList(
                position: index,
                child: PremiumCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      _createRoute(BookDetailsScreen(book: book)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        BookImage(
                          imagePath: book.imagePath,
                          localImagePath: book.localImagePath,
                          width: 50,
                          height: 75,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.author,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: book.availableCopies > 0
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  book.availableCopies > 0
                                      ? '${book.availableCopies} Available'
                                      : 'Out of Stock',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: book.availableCopies > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppAnimations.favoriteHeart(
                          isFavorite: true,
                          activeColor: AppColors.favorite,
                          onTap: () {
                            cart.toggleWishlist(book.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Removed ${book.title} from wishlist',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightAccent.withOpacity(0.1),
            ),
            child: Icon(
              Icons.favorite_border,
              size: 80,
              color: AppColors.getAccentColor(
                Theme.of(context).brightness,
              ).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your wishlist is empty',
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add books to your wishlist to save them for later',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Route _createRoute(Widget destination) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
