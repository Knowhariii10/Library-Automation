import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_colors.dart';
import '../screens/notifications/notifications_screen.dart';
import '../utils/animations.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final String? title;

  const PremiumAppBar({
    super.key,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Logo color: Accent Yellow in Light mode, Golden Yellow in Dark mode
    final logoColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      automaticallyImplyLeading: false, // We handle leading manually
      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                color: AppColors.getTextPrimary(Theme.of(context).brightness),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            )
          : Icon(Icons.local_library_rounded, size: 28, color: logoColor),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: showBackButton
              ? _buildCircleButton(
                  context,
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBackPressed ?? () => Navigator.pop(context),
                  color: isDark ? Colors.white : Colors.black,
                  iconSize: 18,
                )
              : Consumer<ConnectivityProvider>(
                  builder: (context, connectivity, child) {
                    final isOnline =
                        connectivity.status == ConnectivityStatus.online;
                    return _buildCircleButton(
                      context,
                      icon: isOnline ? Icons.wifi : Icons.public_off,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isOnline ? "You are Online" : "You are Offline",
                            ),
                            duration: const Duration(seconds: 1),
                            backgroundColor: isOnline
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        );
                      },
                      color: isOnline
                          ? const Color(0xFF2A9D8F)
                          : AppColors.darkAccent,
                      iconSize: 18,
                    );
                  },
                ),
        ),
      ),
      leadingWidth: 52 + 16, // circle width + padding
      actions: [
        if (actions != null) ...actions!,
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(child: _buildNotificationButton(context)),
        ),
      ],
    );
  }

  Widget _buildCircleButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    double iconSize = 20,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C3138) : const Color(0xFFF5F7FA);
    final borderColor = isDark
        ? const Color(0xFF3A4047)
        : const Color(0xFFE9ECEF);

    return AppAnimations.buttonTap(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Icon(icon, size: iconSize, color: color),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    // TODO: Connect to actual notification provider for unread state
    bool hasUnread = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? const Color(0xFFF8F9FA)
        : const Color(0xFF1E1E1E);

    return Stack(
      children: [
        _buildCircleButton(
          context,
          icon: Icons.notifications_none_rounded,
          color: iconColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
        ),
        if (hasUnread)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFE76F51), // Red Badge
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
