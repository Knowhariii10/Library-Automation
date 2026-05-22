import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/forgot_password_screen.dart';
import 'login_activity_screen.dart';
import '../../theme/app_colors.dart';
import '../../utils/animations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _offlineMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.settings == null) {
        userProvider.fetchSettings();
      } else {
        _syncLocalStateWithProvider(userProvider);
      }
    });
  }

  void _syncLocalStateWithProvider(UserProvider provider) {
    if (provider.settings == null) return;
    setState(() {
      _offlineMode = provider.settings?['system']?['offline_mode'] ?? true;
      _notificationsEnabled =
          provider.settings?['notifications']?['due_date_reminders'] ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isAuthenticated = userProvider.isAuthenticated;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Account & Security'),
          _buildPremiumSettingItem(
            context,
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your login credentials',
            color: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                _createRoute(const ForgotPasswordScreen()),
              );
            },
          ),
          if (isAuthenticated)
            _buildPremiumSettingItem(
              context,
              icon: Icons.shield_outlined,
              title: 'Login Activity',
              subtitle: 'View your recent sign-in history',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  _createRoute(const LoginActivityScreen()),
                );
              },
            ),

          _buildSectionHeader(context, 'Application Settings'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildPremiumSwitchItem(
                context,
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Toggle dark interface theme',
                value: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(val),
                color: Colors.indigo,
              );
            },
          ),
          _buildPremiumSwitchItem(
            context,
            icon: Icons.offline_bolt_outlined,
            title: 'Offline-First Mode',
            subtitle: 'Access data without internet',
            value: _offlineMode,
            onChanged: (val) => setState(() => _offlineMode = val),
            color: Colors.teal,
          ),
          _buildPremiumSettingItem(
            context,
            icon: Icons.sync,
            title: 'Manual Data Sync',
            subtitle: 'Synchronize local database with server',
            color: Colors.green,
            onTap: () async {
              if (isAuthenticated) {
                await userProvider.syncData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Data synced successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Login required to sync data'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              }
            },
          ),

          _buildSectionHeader(context, 'Notifications'),
          _buildPremiumSwitchItem(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            subtitle: 'Reminders for due dates and alerts',
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            color: Colors.orange,
          ),

          _buildSectionHeader(context, 'Library & Policy'),
          _buildPremiumSettingItem(
            context,
            icon: Icons.gavel_outlined,
            title: 'Issue & Return Rules',
            subtitle: 'Max books, issue periods, etc.',
            color: Colors.deepOrange,
            onTap: () {
              final rules = userProvider.settings?['rules'] ?? {};
              _showPremiumPolicyDialog(
                context,
                'Issue & Return Rules',
                '• Max Books: ${rules['max_books_per_user'] ?? 3} per student\n'
                    '• Issue Period: ${rules['issue_period_days'] ?? 14} days\n'
                    '• Renewals: Max ${rules['renewal_limits'] ?? 1} time\n'
                    '• Grace Period: ${rules['grace_period_days'] ?? 2} days\n'
                    '• Policy: ${rules['lost_book_policy'] ?? 'Standard'}',
                Icons.gavel,
              );
            },
          ),
          _buildPremiumSettingItem(
            context,
            icon: Icons.payments_outlined,
            title: 'Fine & Damage Policy',
            subtitle: 'Penalty rates and payment modes',
            color: Colors.red,
            onTap: () {
              final fines = userProvider.settings?['fines'] ?? {};
              _showPremiumPolicyDialog(
                context,
                'Fine Policy',
                '• Overdue Fine: ₹${fines['rate_per_day'] ?? 5} / day\n'
                    '• Max Limit: ₹${fines['max_fine_limit'] ?? 500}\n'
                    '• Payment: ${(fines['payment_modes'] as List?)?.join(', ') ?? 'Cash/Online'}',
                Icons.payments,
              );
            },
          ),
          _buildPremiumSettingItem(
            context,
            icon: Icons.business_outlined,
            title: 'Library Profile',
            subtitle: 'Contact, location and hours',
            color: Colors.blueGrey,
            onTap: () {
              final lib = userProvider.settings?['library'] ?? {};
              _showPremiumPolicyDialog(
                context,
                'Library Profile',
                '• Name: ${lib['name'] ?? 'GCEDPI Library'}\n'
                    '• Hours: ${lib['working_hours'] ?? '9 AM - 5 PM'}\n'
                    '• Email: ${lib['contact_email'] ?? 'N/A'}\n'
                    '• Phone: ${lib['contact_phone'] ?? 'N/A'}\n'
                    '• Location: ${lib['address'] ?? 'Campus A'}',
                Icons.business,
              );
            },
          ),

          const SizedBox(height: 32),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withOpacity(0.5)
                    : AppColors.lightAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'LMS Reader v1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 120), // Space for floating nav
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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

  Widget _buildPremiumSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AppAnimations.cardTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : color.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.getTextSecondary(Theme.of(context).brightness),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSwitchItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.getAccentColor(Theme.of(context).brightness),
          ),
        ],
      ),
    );
  }

  void _showPremiumPolicyDialog(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getAccentColor(
                    Theme.of(context).brightness,
                  ).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: AppColors.getAccentColor(Theme.of(context).brightness),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 24),
              AppAnimations.buttonTap(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.getAccentColor(
                      Theme.of(context).brightness,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'GOT IT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(
                        Theme.of(context).brightness,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
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
