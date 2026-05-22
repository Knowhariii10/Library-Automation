import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/login_required_widget.dart';
import '../../theme/app_colors.dart';
import '../../utils/animations.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/logout_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.isAuthenticated) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const LoginRequiredWidget(
              message: 'Login to view your student profile and QR code',
            ),
          );
        }

        final user = userProvider.user!;
        final nameParts = user.name
            .split(' ')
            .where((e) => e.isNotEmpty)
            .toList();
        final initials = nameParts.isEmpty
            ? 'U'
            : nameParts.map((e) => e[0]).take(2).join().toUpperCase();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          extendBody: true,
          appBar: const PremiumAppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 120,
            ), // Global Scroll Padding
            child: Column(
              children: [
                // Premium Header with Gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.darkSurface,
                              AppColors.darkSurface.withOpacity(0.8),
                            ]
                          : [
                              AppColors.lightAccent.withOpacity(0.2),
                              AppColors.lightAccent.withOpacity(0.05),
                            ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar with animated gradient border
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.getAccentColor(
                                Theme.of(context).brightness,
                              ),
                              AppColors.getAccentColor(
                                Theme.of(context).brightness,
                              ).withOpacity(0.5),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: isDark
                              ? AppColors.darkBackground
                              : Colors.white,
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: 36,
                              color: AppColors.getAccentColor(
                                Theme.of(context).brightness,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Premium QR Code Section
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.getAccentColor(
                              Theme.of(context).brightness,
                            ).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: QrImageView(
                          data: jsonEncode({
                            "purpose": "ATTENDANCE",
                            "user_id": user.id,
                          }),
                          version: QrVersions.auto,
                          size: 200.0,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.circle,
                            color: AppColors.getTextPrimary(Brightness.light),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Attendance QR Code',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan at library entrance for check-in',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // User Info Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildInfoCard(
                        context,
                        Icons.email_outlined,
                        'Email Address',
                        user.email,
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.badge_outlined,
                        'Student ID',
                        user.studentId,
                        Colors.purple,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.school_outlined,
                        'Department',
                        user.department,
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.calendar_today_outlined,
                        'Academic Year',
                        user.year,
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.phone_outlined,
                        'Phone Number',
                        user.phone,
                        Colors.teal,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppAnimations.buttonTap(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text(
                            'LOGOUT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                ),
                const SizedBox(height: 24), // Extra space at bottom
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
