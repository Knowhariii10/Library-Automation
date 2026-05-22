import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/database_helper.dart';
import '../../services/sync_service.dart';
import '../../widgets/login_required_widget.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/shimmer_loading.dart';
import '../../utils/animations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  Future<void> _refresh() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final notifProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    await SyncService().syncData(userProvider, null);
    await notifProvider.loadNotifications();
  }

  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, NotificationProvider>(
      builder: (context, userProvider, notifProvider, child) {
        if (!userProvider.isAuthenticated) {
          return Scaffold(
            appBar: AppBar(title: const Text('Notifications')),
            body: const LoginRequiredWidget(
              message: 'Login to view your system notifications.',
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          appBar: const PremiumAppBar(),
          body: notifProvider.isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ShimmerLoading.listTile(),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: notifProvider.notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 120, // Global Scroll Padding
                          ),
                          itemCount: notifProvider.notifications.length,
                          itemBuilder: (context, index) {
                            final notification =
                                notifProvider.notifications[index];
                            final bool isRead =
                                (notification['read_status'] == 1);
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;

                            return AppAnimations.staggeredList(
                              position: index,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : Colors.grey.withOpacity(0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isRead
                                          ? (isDark
                                                ? Colors.grey[800]
                                                : Colors.grey[100])
                                          : AppColors.getAccentColor(
                                              Theme.of(context).brightness,
                                            ).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications_rounded,
                                      color: isRead
                                          ? Colors.grey
                                          : AppColors.getAccentColor(
                                              Theme.of(context).brightness,
                                            ),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    notification['message'] ?? 'No message',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          fontWeight: isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                          color: isRead
                                              ? AppColors.getTextSecondary(
                                                  Theme.of(context).brightness,
                                                )
                                              : AppColors.getTextPrimary(
                                                  Theme.of(context).brightness,
                                                ),
                                        ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      _formatDateTime(
                                        notification['created_at'],
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.getTextSecondary(
                                              Theme.of(context).brightness,
                                            ),
                                            fontSize: 11,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We will notify you about your reservations\nand library activities here.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
                const SizedBox(height: 32),
                AppAnimations.buttonTap(
                  onTap: _refresh,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getAccentColor(
                        Theme.of(context).brightness,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getAccentColor(
                            Theme.of(context).brightness,
                          ).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'REFRESH',
                      style: TextStyle(
                        color: Colors.black, // Always indicate action clearly
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
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
}
