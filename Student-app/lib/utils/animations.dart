import 'package:flutter/material.dart';

/// Premium animation utilities for micro-interactions
/// Provides reusable animations for buttons, cards, and favorites
class AppAnimations {
  AppAnimations._(); // Private constructor

  // ==========================================================================
  // ANIMATION DURATIONS
  // ==========================================================================

  /// Quick animation for button taps
  static const Duration quick = Duration(milliseconds: 150);

  /// Standard animation for most transitions
  static const Duration standard = Duration(milliseconds: 250);

  /// Slower animation for complex transitions
  static const Duration slow = Duration(milliseconds: 350);

  // ==========================================================================
  // ANIMATION CURVES
  // ==========================================================================

  /// Smooth ease-out curve for natural motion
  static const Curve easeOut = Curves.easeOut;

  /// Elastic curve for playful animations (e.g., favorites)
  static const Curve elastic = Curves.elasticOut;

  /// Bounce curve for attention-grabbing animations
  static const Curve bounce = Curves.bounceOut;

  // ==========================================================================
  // BUTTON TAP ANIMATION
  // ==========================================================================

  /// Wraps a widget with tap scale animation
  /// Scales down to 0.97 when pressed
  ///
  /// Usage:
  /// ```dart
  /// AppAnimations.buttonTap(
  ///   child: ElevatedButton(...),
  ///   onTap: () => print('Tapped!'),
  /// )
  /// ```
  static Widget buttonTap({
    required Widget child,
    required VoidCallback onTap,
    double scale = 0.97,
  }) {
    return _TapScaleAnimation(onTap: onTap, scale: scale, child: child);
  }

  // ==========================================================================
  // CARD TAP ANIMATION
  // ==========================================================================

  /// Wraps a card with tap animation that changes elevation
  /// Scales down to 0.98 when pressed
  ///
  /// Usage:
  /// ```dart
  /// AppAnimations.cardTap(
  ///   child: Card(...),
  ///   onTap: () => Navigator.push(...),
  /// )
  /// ```
  static Widget cardTap({
    required Widget child,
    required VoidCallback onTap,
    double scale = 0.98,
  }) {
    return _TapScaleAnimation(onTap: onTap, scale: scale, child: child);
  }

  // ==========================================================================
  // FAVORITE HEART ANIMATION
  // ==========================================================================

  /// Animates a favorite icon with pop effect
  /// Uses elastic curve for playful bounce
  ///
  /// Usage:
  /// ```dart
  /// AppAnimations.favoriteHeart(
  ///   isFavorite: _isFavorite,
  ///   onTap: () => setState(() => _isFavorite = !_isFavorite),
  /// )
  /// ```
  static Widget favoriteHeart({
    required bool isFavorite,
    required VoidCallback onTap,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    return _FavoriteHeartAnimation(
      isFavorite: isFavorite,
      onTap: onTap,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
    );
  }

  // ==========================================================================
  // CROSS-FADE ANIMATION
  // ==========================================================================

  /// Smoothly cross-fades between two widgets
  ///
  /// Usage:
  /// ```dart
  /// AppAnimations.crossFade(
  ///   showFirst: _isLoading,
  ///   first: CircularProgressIndicator(),
  ///   second: Text('Content'),
  /// )
  /// ```
  static Widget crossFade({
    required bool showFirst,
    required Widget first,
    required Widget second,
  }) {
    return AnimatedCrossFade(
      firstChild: first,
      secondChild: second,
      crossFadeState: showFirst
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      duration: standard,
      firstCurve: easeOut,
      secondCurve: easeOut,
    );
  }

  static Widget staggeredList({
    required int position,
    required Widget child,
    Duration duration = standard,
  }) {
    return _StaggeredListAnimation(
      position: position,
      duration: duration,
      child: child,
    );
  }
}

// ============================================================================
// PRIVATE ANIMATION WIDGETS
// ============================================================================

/// Internal widget for tap scale animation
class _TapScaleAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const _TapScaleAnimation({
    required this.child,
    required this.onTap,
    required this.scale,
  });

  @override
  State<_TapScaleAnimation> createState() => _TapScaleAnimationState();
}

class _TapScaleAnimationState extends State<_TapScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.quick,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Internal widget for favorite heart animation
class _FavoriteHeartAnimation extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final Color? activeColor;
  final Color? inactiveColor;

  const _FavoriteHeartAnimation({
    required this.isFavorite,
    required this.onTap,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<_FavoriteHeartAnimation> createState() =>
      _FavoriteHeartAnimationState();
}

class _FavoriteHeartAnimationState extends State<_FavoriteHeartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.standard,
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: AppAnimations.elastic)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FavoriteHeartAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite && !oldWidget.isFavorite) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.activeColor ?? Colors.red;
    final inactiveColor = widget.inactiveColor ?? theme.iconTheme.color;

    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          widget.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: widget.isFavorite ? activeColor : inactiveColor,
          size: 24,
        ),
      ),
    );
  }
}

/// Internal widget for staggered list animation
class _StaggeredListAnimation extends StatefulWidget {
  final int position;
  final Widget child;
  final Duration duration;

  const _StaggeredListAnimation({
    required this.position,
    required this.child,
    required this.duration,
  });

  @override
  State<_StaggeredListAnimation> createState() =>
      _StaggeredListAnimationState();
}

class _StaggeredListAnimationState extends State<_StaggeredListAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Stagger delay
    Future.delayed(Duration(milliseconds: widget.position * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
