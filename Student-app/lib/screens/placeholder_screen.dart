import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_app_bar.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: PremiumAppBar(title: title),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getAccentColor(
                  theme.brightness,
                ).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.construction_rounded,
                size: 64,
                color: AppColors.getAccentColor(theme.brightness),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$title Feature',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(theme.brightness),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.getTextSecondary(theme.brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
