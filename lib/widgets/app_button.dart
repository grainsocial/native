import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final AppButtonVariant variant;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.height = 44,
    this.borderRadius = 6,
    this.fontSize = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryColor = theme.colorScheme.primary;
    final Color secondaryColor = theme.colorScheme.surfaceContainerHighest;
    final Color secondaryBorder = theme.dividerColor;
    final Color secondaryText = theme.colorScheme.onSurface;
    final Color primaryText = theme.colorScheme.onPrimary;
    final bool isPrimary = variant == AppButtonVariant.primary;

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? primaryColor : secondaryColor,
          foregroundColor: isPrimary ? primaryText : secondaryText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: isPrimary ? BorderSide.none : BorderSide(color: secondaryBorder, width: 1),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: isPrimary ? primaryColor : secondaryColor,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: isPrimary ? primaryText : secondaryText),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
