import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Compact connectivity status indicator for app bar
/// Features:
/// - WiFi icon (green) when online
/// - Globe icon (amber) with pulse animation when offline
/// - Positioned in top-left of app bar
/// - Shows tooltip on tap
class ConnectivityIndicator extends StatefulWidget {
  final bool isOnline;

  const ConnectivityIndicator({
    super.key,
    required this.isOnline,
  });

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (!widget.isOnline) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ConnectivityIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      if (widget.isOnline) {
        _pulseController.stop();
        _pulseController.value = 1.0;
      } else {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.isOnline ? Icons.wifi : Icons.public;
    final color = widget.isOnline
        ? AppColors.onlineGreen
        : AppColors.offlineAmber;
    final tooltipMessage = widget.isOnline
        ? 'Online'
        : 'Offline Mode - Cached Content';

    return Tooltip(
      message: tooltipMessage,
      child: widget.isOnline
          ? Icon(icon, color: color, size: 20)
          : FadeTransition(
              opacity: _pulseAnimation,
              child: Icon(icon, color: color, size: 20),
            ),
    );
  }
}