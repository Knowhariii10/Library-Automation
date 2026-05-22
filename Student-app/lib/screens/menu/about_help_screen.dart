import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';

class AboutHelpScreen extends StatelessWidget {
  const AboutHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final lib = userProvider.settings?['library'] ?? {};
    final libName = lib['name'] ?? 'GCEDPI';
    final libEmail = lib['contact_email'] ?? 'gcedpilibrary6135@gmail.com';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('About & Help'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120), // Global scroll padding
        child: Column(
          children: [
            _buildHeader(context),
            _buildAboutSection(context, libName),
            _buildHelpSection(context),
            _buildFooter(context, libName, libEmail),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightAccent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories,
            size: 80,
            color: isDark ? AppColors.darkAccent : Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'LMS Reader',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Always white on accent/dark surface
              letterSpacing: 1.2,
            ),
          ),
          const Text(
            'Version 1.0.0',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, String libName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Vision',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.getAccentColor(Theme.of(context).brightness),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'At $libName, we believe knowledge should be at your fingertips. The Library Management System (LMS) is crafted to bridge the gap between students and the vast ocean of literature. Whether you’re deep into research or looking for your next weekend read, LMS Reader ensures a seamless, modern, and reliable experience.',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkAccent.withOpacity(0.1)
                  : AppColors.lightAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.getAccentColor(
                  Theme.of(context).brightness,
                ).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.offline_bolt,
                  color: AppColors.getAccentColor(Theme.of(context).brightness),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Built with Offline-First architecture. Access your data anytime, anywhere.',
                    style: TextStyle(
                      color: AppColors.getAccentColor(
                        Theme.of(context).brightness,
                      ),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: isDark ? AppColors.darkSurface.withOpacity(0.5) : Colors.grey[50],
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Use the App',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.getAccentColor(Theme.of(context).brightness),
            ),
          ),
          const SizedBox(height: 20),
          _buildStep(
            context,
            '1',
            Icons.search_rounded,
            'Discover Knowledge',
            'Browse our extensive catalog or use the voice search to find exactly what you need.',
          ),
          _buildStep(
            context,
            '2',
            Icons.bookmark_added_rounded,
            'Instant Reservation',
            'Found something? Reserve it instantly to ensure it\'s waiting for you at the library.',
          ),
          _buildStep(
            context,
            '3',
            Icons.qr_code_scanner_rounded,
            'Digital Pickup',
            'Visit the library counter and show your digital record for a swift, paperless pickup.',
          ),
          _buildStep(
            context,
            '4',
            Icons.sync_rounded,
            'Stay Informed',
            'Track your borrowed books, history, and notifications. Everything stays in sync automatically.',
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    String number,
    IconData icon,
    String title,
    String desc,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppColors.getAccentColor(Theme.of(context).brightness);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white, // Always white on accent
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
                Row(
                  children: [
                    Icon(icon, size: 20, color: accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, String libName, String libEmail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppColors.getAccentColor(Theme.of(context).brightness);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Need more help?',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact us at $libEmail',
            style: TextStyle(
              color: accentColor,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '© 2026 Library Management System | $libName',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
