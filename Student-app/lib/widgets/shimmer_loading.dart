import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Premium shimmer loading animations
/// Provides skeleton screens with gradient animation that replaces circular progress indicators
class ShimmerLoading extends StatefulWidget {
  /// Width of the shimmer element
  final double? width;

  /// Height of the shimmer element
  final double? height;

  /// Border radius (default: 8.0 for rectangular elements)
  final double borderRadius;

  /// Whether to show a circular shimmer (for avatars, icons, etc.)
  final bool isCircle;

  const ShimmerLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.isCircle = false,
  });

  /// Creates a shimmer for a book card
  factory ShimmerLoading.bookCard() {
    return const ShimmerLoading(
      width: double.infinity,
      height: 180,
      borderRadius: 16.0,
    );
  }

  /// Creates a shimmer for a list tile
  factory ShimmerLoading.listTile() {
    return const ShimmerLoading(
      width: double.infinity,
      height: 80,
      borderRadius: 12.0,
    );
  }

  /// Creates a shimmer for a circular avatar
  factory ShimmerLoading.avatar({double size = 48}) {
    return ShimmerLoading(
      width: size,
      height: size,
      isCircle: true,
    );
  }

  /// Creates a shimmer for text (single line)
  factory ShimmerLoading.text({double? width, double height = 16}) {
    return ShimmerLoading(
      width: width,
      height: height,
      borderRadius: 4.0,
    );
  }

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors for shimmer gradient
    final baseColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final highlightColor = isDark
        ? AppColors.darkSurface.withOpacity(0.5)
        : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton screen loader for book grid/list
class BookGridSkeleton extends StatelessWidget {
  const BookGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => ShimmerLoading.bookCard(),
    );
  }
}

/// Skeleton screen loader for transaction list
class TransactionListSkeleton extends StatelessWidget {
  const TransactionListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading.listTile(),
      ),
    );
  }
}

/// Skeleton screen loader for cart items
class CartItemSkeleton extends StatelessWidget {
  const CartItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const ShimmerLoading(
              width: 60,
              height: 80,
              borderRadius: 8,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading.text(width: 200),
                  const SizedBox(height: 8),
                  ShimmerLoading.text(width: 120, height: 14),
                  const SizedBox(height: 8),
                  ShimmerLoading.text(width: 80, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
