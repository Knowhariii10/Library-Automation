import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/database_helper.dart';
import '../../providers/user_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../services/sync_service.dart';
import '../../widgets/login_required_widget.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_card.dart';
import '../../utils/animations.dart';
import 'dart:async';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationProvider>().loadReservations();
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _refresh() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final resProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );
    if (userProvider.isAuthenticated) {
      await SyncService().syncData(userProvider, bookProvider);
      await resProvider.loadReservations();
    }
  }

  Future<void> _handleCancel(String reservationId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel PreHold'),
        content: const Text('Are you sure you want to cancel this PreHold?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cancelling PreHold...')));
    }

    try {
      final apiService = ApiService();
      final result = await apiService.cancelReservation(
        userProvider.token!,
        reservationId,
      );

      if (!mounted) return;

      if (result != null && result['success'] == true) {
        // Delete from local DB immediately
        await DatabaseHelper.instance.deleteReservation(reservationId);

        // Reload list
        if (mounted) {
          context.read<ReservationProvider>().loadReservations();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PreHold cancelled successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result?['error'] ?? 'Cancellation failed. Please try again.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Check your connection.'),
          ),
        );
      }
    }
  }

  String _getTimeLeft(String expiresAtStr) {
    try {
      final expiry = DateTime.parse(expiresAtStr);
      final now = DateTime.now();
      final difference = expiry.difference(now);

      if (difference.isNegative) return 'Expired';

      if (difference.inHours > 0) {
        return '${difference.inHours}h ${difference.inMinutes % 60}m left';
      } else {
        return '${difference.inMinutes}m left';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ReservationProvider>(
      builder: (context, userProvider, resProvider, child) {
        if (!userProvider.isStudent) {
          return const Scaffold(
            appBar: PremiumAppBar(title: 'My Reservations'),
            body: LoginRequiredWidget(
              message:
                  'Guests cannot have reservations. Please login as a student.',
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          appBar: PremiumAppBar(
            title: 'My PreHolds',
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: AppColors.getTextPrimary(Theme.of(context).brightness),
                ),
                onPressed: _refresh,
              ),
            ],
          ),
          body: resProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : resProvider.reservations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 120, // Global Scroll Padding
                    ),
                    itemCount: resProvider.reservations.length,
                    itemBuilder: (context, index) {
                      final res = resProvider.reservations[index];
                      final timeLeft = _getTimeLeft(res['expires_at']);
                      final isExpired = timeLeft == 'Expired';

                      return AppAnimations.staggeredList(
                        position: index,
                        child: PremiumCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isExpired
                                            ? AppColors.error.withOpacity(0.1)
                                            : AppColors.success.withOpacity(
                                                0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isExpired
                                              ? AppColors.error.withOpacity(0.3)
                                              : AppColors.success.withOpacity(
                                                  0.3,
                                                ),
                                        ),
                                      ),
                                      child: Text(
                                        res['status'] ?? 'ACTIVE',
                                        style: TextStyle(
                                          color: isExpired
                                              ? AppColors.error
                                              : AppColors.success,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer_rounded,
                                          size: 14,
                                          color: isExpired
                                              ? AppColors.error
                                              : AppColors.warning,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          timeLeft,
                                          style: TextStyle(
                                            color: isExpired
                                                ? AppColors.error
                                                : AppColors.warning,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (!isExpired) ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline_rounded,
                                              size: 20,
                                              color: AppColors.error
                                                  .withOpacity(0.8),
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () =>
                                                _handleCancel(res['id']),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  res['book_title'] ?? 'Unknown Book',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.getSurfaceColor(
                                      Theme.of(context).brightness,
                                    ).withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.getBorderColor(
                                        Theme.of(context).brightness,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.event_available_rounded,
                                        size: 16,
                                        color: AppColors.getTextSecondary(
                                          Theme.of(context).brightness,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Expires: ${res['expires_at'].split('T')[0]} ${res['expires_at'].split('T').length > 1 ? res['expires_at'].split('T')[1].substring(0, 5) : ""}',
                                          style: TextStyle(
                                            color: AppColors.getTextSecondary(
                                              Theme.of(context).brightness,
                                            ),
                                            fontSize: 12,
                                            fontFamily: 'Courier',
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
                    color: AppColors.getSurfaceColor(
                      Theme.of(context).brightness,
                    ).withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 64,
                    color: AppColors.getTextSecondary(
                      Theme.of(context).brightness,
                    ).withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No active PreHolds',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AppAnimations.buttonTap(
                  onTap: _refresh,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getAccentColor(
                        Theme.of(context).brightness,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'REFRESH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(
                          Theme.of(context).brightness,
                        ),
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
