import 'package:flutter/material.dart';
import '../core/constants.dart';

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const GlassButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [AppColors.brightTealBlue, Color(0xFF0A5C87)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : Colors.transparent,
          border: isPrimary
              ? null
              : Border.all(color: AppColors.brightTealBlue, width: 2),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.brightTealBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.heading.copyWith(
              color: isPrimary ? Colors.white : AppColors.brightTealBlue,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
