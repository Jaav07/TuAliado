import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color softBlue = Color(0xFFE3F2FD);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFF5F6368);
  static const Color shadowBlue = Color(0x4D1976D2);
  static const Color cyanMedic = Color(0xFF00BCD4);

  // Paleta calida (Home y Bienvenida)
  static const Color warmCream = Color(0xFFFBF8F3);
  static const Color deepTeal = Color(0xFF1D4E5F);
  static const Color tealSoft = Color(0xFFE1F5EE);
  static const Color tealText = Color(0xFF085041);
  static const Color amber = Color(0xFFE8A33D);
  static const Color amberText = Color(0xFF633806);
  static const Color warmTextDark = Color(0xFF2C2C2A);
  static const Color warmTextMuted = Color(0xFF5F5E5A);
  static const Color warmBorder = Color(0xFFE5E0D6);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundWhite,
      textTheme: GoogleFonts.nunitoTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.lightBlue,
        surface: AppColors.backgroundWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(230, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          elevation: 8,
          shadowColor: AppColors.shadowBlue,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
