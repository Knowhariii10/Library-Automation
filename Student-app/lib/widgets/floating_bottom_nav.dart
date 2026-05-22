import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Premium floating pill-shaped bottom navigation bar
/// Features:
/// - Solid Lemon/Golden Yellow background
/// - Profile tab centered and emphasized
/// - Smooth animations
/// - New tab order: Home, Transaction, Profile, Cart, Menu
class FloatingBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const FloatingBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Background color: Lemon Yellow (Light) / Golden Yellow (Dark)
    final backgroundColor = isDark
        ? AppColors.darkAccent
        : AppColors.lightAccent;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 76, // Increased to fix overflow with padding
      decoration: BoxDecoration(
        color: backgroundColor, // Solid color
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'StudyHub',
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
            isDark: isDark,
          ),
          _NavItem(
            icon: Icons.swap_horiz_rounded,
            label: 'Activity',
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
            isDark: isDark,
          ),

          // Center QR Scan Tab
          _NavItem(
            icon: Icons.qr_code_scanner_rounded,
            label: 'MySpace',
            isSelected: selectedIndex == 2,
            onTap: () => onTap(2),
            isDark: isDark,
            isCenter: true,
          ),

          _NavItem(
            icon: Icons.shopping_cart_outlined,
            label: 'vault',
            isSelected: selectedIndex == 3,
            onTap: () => onTap(3),
            isDark: isDark,
          ),
          _NavItem(
            icon: Icons.menu_rounded,
            label: 'Menu',
            isSelected: selectedIndex == 4,
            onTap: () => onTap(4),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final bool isCenter;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.isCenter = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Bubble animation
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    // Active Color: White
    // Inactive Color: Dark Grey (Light Mode) / White (Dark Mode)
    final activeColor = Colors.white;
    final inactiveColor = widget.isDark
        ? Colors.white
        : const Color(0xFF2C3E50);

    return Expanded(
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: widget.isCenter && widget.isSelected
                      ? BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        )
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Add glow effect for center QR button
                          if (widget.isCenter)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                          Icon(
                            widget.icon,
                            color: widget.isSelected
                                ? activeColor
                                : inactiveColor,
                            size: widget.isCenter ? 28 : 22, // Larger for QR
                          ),
                          if (widget.isSelected && !widget.isCenter)
                            Positioned(
                              top: -8,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.isSelected
                              ? activeColor
                              : inactiveColor,
                          fontSize: widget.isCenter ? 10 : 11,
                          fontWeight: widget.isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
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
    );
  }
}
