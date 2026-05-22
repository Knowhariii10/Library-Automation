import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_card.dart';
import '../../utils/animations.dart';

class LoginActivityScreen extends StatelessWidget {
  const LoginActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      extendBodyBehindAppBar: true,
      appBar: const PremiumAppBar(title: 'Login Activity'),
      body: user == null
          ? Center(
              child: Text(
                'Please login to view activity',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.getTextSecondary(theme.brightness),
                ),
              ),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  AppAnimations.staggeredList(
                    position: 0,
                    child: Text(
                      'Recent Sessions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getAccentColor(theme.brightness),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  AppAnimations.staggeredList(
                    position: 1,
                    child: PremiumCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.success,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Last Successful Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getTextPrimary(
                                        theme.brightness,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.lastLogin != null
                                        ? DateFormat(
                                            'MMM dd, yyyy • hh:mm a',
                                          ).format(user.lastLogin!)
                                        : 'Information not available',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.getTextSecondary(
                                        theme.brightness,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  AppAnimations.staggeredList(
                    position: 2,
                    child: PremiumCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_add_outlined,
                                color: AppColors.info,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Created',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getTextPrimary(
                                        theme.brightness,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Account registered successfully',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.getTextSecondary(
                                        theme.brightness,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  AppAnimations.staggeredList(
                    position: 3,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security_rounded,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Security Tip',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'If you notice any unusual login activity, please change your password immediately from the Account settings to secure your account.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.getTextPrimary(theme.brightness),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
