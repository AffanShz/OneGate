import 'package:flutter/material.dart';
import '../core/constants.dart';

class GlassTextField extends StatelessWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final int maxLines;

  const GlassTextField({
    Key? key,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        maxLines: maxLines,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: AppTextStyles.body.copyWith(
            color: AppColors.shadowGrey.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
