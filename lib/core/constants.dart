import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color porcelain = Color(0xFFFBFEF9);
  static const Color shadowGrey = Color(0xFF191923);
  static const Color brightTealBlue = Color(0xFF0E79B2);
  static const Color rosewood = Color(0xFFBF1363);
  static const Color glassBorder = Colors.white54;
}

class AppTextStyles {
  static TextStyle get display => GoogleFonts.outfit(
    color: AppColors.shadowGrey,
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get heading => GoogleFonts.outfit(
    color: AppColors.shadowGrey,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get body => GoogleFonts.outfit(
    color: AppColors.shadowGrey,
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static TextStyle get label => GoogleFonts.outfit(
    color: AppColors.shadowGrey.withOpacity(0.7),
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
