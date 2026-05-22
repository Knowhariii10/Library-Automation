import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../auth/auth_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../reservations/reservations_screen.dart';
import '../rentals/rentals_screen.dart';
import '../settings/settings_screen.dart';
import 'about_help_screen.dart';
import 'fines_screen.dart';
import 'overdue_screen.dart';
import '../../theme/app_colors.dart';
import '../../utils/animations.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/logout_dialog.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final isAuthenticated = userProvider.isAuthenticated;

        String displayName = isAuthenticated ? user!.name : 'Guest';
        String displayInfo = isAuthenticated
            ? 'Student | ${user!.department}'
            : 'Sign in to access all features';
        final nameParts =
            user?.name.split(' ').where((e) => e.isNotEmpty).toList() ?? [];
        String initials = isAuthenticated
            ? (nameParts.isEmpty
                  ? 'U'
                  : nameParts.map((e) => e[0]).take(2).join().toUpperCase())
            : 'G';

        return Scaffold(
          extendBody: true,
          appBar: const PremiumAppBar(),
          body: ListView(
            padding: const EdgeInsets.only(
              bottom: 120,
            ), // Global Scroll Padding
            children: [
              // Premium User Profile Header
              _buildUserHeader(
                context,
                initials,
                displayName,
                displayInfo,
                isAuthenticated,
              ),

              const SizedBox(height: 8),

              // Personal Section
              _buildSectionHeader(context, 'Personal'),
              _buildPremiumMenuItem(
                context,
                Icons.favorite_border,
                'My Wishlist',
                'Saved books and favorites',
                // Removed gradient, using solid surface color with shadow
                onTap: () {
                  if (userProvider.isStudent) {
                    Navigator.push(
                      context,
                      _createRoute(const WishlistScreen()),
                    );
                  } else {
                    _showStudentLoginRequired(context, 'Wishlist');
                  }
                },
              ),
              _buildPremiumMenuItem(
                context,
                Icons.book_outlined,
                'Currently Rented',
                'Books you have checked out',
                onTap: () {
                  if (userProvider.isStudent) {
                    Navigator.push(
                      context,
                      _createRoute(const RentalsScreen()),
                    );
                  } else {
                    _showStudentLoginRequired(context, 'Rented Books');
                  }
                },
              ),
              _buildPremiumMenuItem(
                context,
                Icons.alarm,
                'My Reservations',
                'Upcoming book reservations',
                onTap: () {
                  if (userProvider.isStudent) {
                    Navigator.push(
                      context,
                      _createRoute(const ReservationsScreen()),
                    );
                  } else {
                    _showStudentLoginRequired(context, 'Reservations');
                  }
                },
              ),

              const SizedBox(height: 16),

              // Library Activity
              _buildSectionHeader(context, 'Library Activity'),
              _buildPremiumMenuItem(
                context,
                Icons.history_toggle_off,
                'Overdue Details',
                'Check overdue books',
                onTap: () {
                  if (userProvider.isStudent) {
                    Navigator.push(
                      context,
                      _createRoute(const OverdueScreen()),
                    );
                  } else {
                    _showStudentLoginRequired(context, 'Overdue Details');
                  }
                },
              ),
              _buildPremiumMenuItem(
                context,
                Icons.account_balance_wallet_outlined,
                'Fines & Payments',
                'View and pay your fines',
                onTap: () {
                  if (userProvider.isStudent) {
                    Navigator.push(context, _createRoute(const FinesScreen()));
                  } else {
                    _showStudentLoginRequired(context, 'Fines & Payments');
                  }
                },
              ),

              const SizedBox(height: 16),

              // App Settings
              _buildSectionHeader(context, 'App Settings'),
              _buildPremiumMenuItem(
                context,
                Icons.settings_outlined,
                'Settings',
                'Preferences and configuration',
                onTap: () => Navigator.push(
                  context,
                  _createRoute(const SettingsScreen()),
                ),
              ),
              _buildPremiumMenuItem(
                context,
                Icons.info_outline,
                'About & Help',
                'App info and support',
                onTap: () => Navigator.push(
                  context,
                  _createRoute(const AboutHelpScreen()),
                ),
              ),

              if (isAuthenticated) ...[
                const SizedBox(height: 16),
                _buildSectionHeader(context, 'Account'),
                _buildPremiumMenuItem(
                  context,
                  Icons.logout,
                  'Logout',
                  'Sign out of your account',
                  color: AppColors.error,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => LogoutDialog(
                        onLogout: () {
                          userProvider.logout();
                          Navigator.pop(context); // Close dialog
                        },
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserHeader(
    BuildContext context,
    String initials,
    String displayName,
    String displayInfo,
    bool isAuthenticated,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurface, AppColors.darkSurface.withOpacity(0.8)]
              : [
                  AppColors.lightAccent.withOpacity(0.2),
                  AppColors.lightAccent.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with gradient border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.getAccentColor(Theme.of(context).brightness),
                  AppColors.getAccentColor(
                    Theme.of(context).brightness,
                  ).withOpacity(0.5),
                ],
              ),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
              child: Text(
                initials,
                style: TextStyle(
                  color: AppColors.getAccentColor(Theme.of(context).brightness),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayInfo,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (!isAuthenticated)
            AppAnimations.buttonTap(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getAccentColor(Theme.of(context).brightness),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'LOGIN',
                  style: TextStyle(
                    color: AppColors.getTextPrimary(
                      Theme.of(context).brightness,
                    ),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(context, _createRoute(const AuthScreen()));
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: AppColors.getTextSecondary(Theme.of(context).brightness),
        ),
      ),
    );
  }

  Widget _buildPremiumMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    String subtitle, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor =
        color ?? AppColors.getAccentColor(Theme.of(context).brightness);

    // Premium styling: Consistent Shadow, Surface Color
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3138) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000), // 10% Opacity Black
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppAnimations.cardTap(
        onTap: onTap ?? () {},
        child: ListTile(
          // Removed inner container to avoid double padding/decoration
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: itemColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: itemColor, size: 24),
          ),
          title: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.getTextSecondary(Theme.of(context).brightness),
          ),
        ),
      ),
    );
  }

  void _showStudentLoginRequired(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is only available for registered students.'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'LOGIN',
          textColor: AppColors.getAccentColor(Theme.of(context).brightness),
          onPressed: () {
            Navigator.push(context, _createRoute(const AuthScreen()));
          },
        ),
      ),
    );
  }

  // Smooth page transition
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
