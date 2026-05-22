import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Premium search bar with rectangular design and subtle styling
/// Features:
/// - Rectangular shape with 8px border radius
/// - No filter button (simplified)
/// - Microphone icon inside as trailing icon
/// - Subtle shadow in light mode, border in dark mode
class PremiumSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onMicTap;
  final TextEditingController? controller;

  const PremiumSearchBar({
    super.key,
    this.hintText = 'Search books, authors, subjects...',
    this.onChanged,
    this.onMicTap,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSearchBackground
            : AppColors.lightSearchBackground,
        borderRadius: BorderRadius.circular(8),
        border: isDark
            ? Border.all(color: AppColors.darkBorder, width: 1)
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 15,
          color: AppColors.getTextPrimary(theme.brightness),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 15,
            color: AppColors.getTextSecondary(theme.brightness),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.getTextSecondary(theme.brightness),
            size: 22,
          ),
          suffixIcon: onMicTap != null
              ? IconButton(
                  icon: Icon(
                    Icons.mic_outlined,
                    color: AppColors.getTextSecondary(theme.brightness),
                    size: 22,
                  ),
                  onPressed: onMicTap,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.getAccentColor(theme.brightness),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
