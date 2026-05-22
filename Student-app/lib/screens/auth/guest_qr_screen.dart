import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../home/home_screen.dart';
import 'dart:convert';
import '../../theme/app_colors.dart';
import '../../widgets/premium_card.dart';

class GuestQRScreen extends StatelessWidget {
  final String name;
  final String email;
  final String purpose;
  final String userId;

  const GuestQRScreen({
    super.key,
    required this.name,
    required this.email,
    required this.purpose,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = AppColors.getAccentColor(theme.brightness);
    final textColor = AppColors.getTextPrimary(theme.brightness);
    final surfaceColor = AppColors.getSurfaceColor(theme.brightness);

    // Generate QR payload
    final qrData = jsonEncode({
      'user_id': userId,
      'purpose': 'ATTENDANCE', // This triggers the attendance logic in backend
      'type': 'GUEST',
      'name': name,
      'guest_purpose': purpose,
    });

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Guest Entry Pass',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.qr_code_2_rounded,
                size: 50,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              name,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondary(theme.brightness),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // QR Code Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white, // QR needs high contrast, keep white
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220.0,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: isDark ? Colors.black : AppColors.lightTextPrimary,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: isDark ? Colors.black : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Scan at Reception',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.black : accentColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Purpose Card
            PremiumCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.badge_outlined, color: accentColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Purpose of Visit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.getTextSecondary(theme.brightness),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          purpose,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: accentColor,
                foregroundColor: isDark
                    ? AppColors.darkBackground
                    : Colors.white,
                elevation: 4,
                shadowColor: accentColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text(
                'GO TO HOME',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
