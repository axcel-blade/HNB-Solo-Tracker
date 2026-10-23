import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  const AppColors._();

  static const navy = Color(0xFF10233F);
  static const headerEnd = Color(0xFF1E467B);
  static const blue = Color(0xFF2463EB);
  static const bg = Color(0xFFF3F6FB);
  static const ink = Color(0xFF172338);
  static const muted = Color(0xFF68778D);
  static const line = Color(0xFFE3E9F2);
  static const green = Color(0xFF11845B);
  static const subtitle = Color(0xFFD8E6FF);
  static const privacy = Color(0xFFD9E7FF);
  static const dangerBg = Color(0xFFFFF0F0);
  static const dangerFg = Color(0xFFA32727);
  static const dangerBorder = Color(0xFFFFD7D7);
  static const tagBg = Color(0xFFEDF3FF);
  static const tagFg = Color(0xFF2455A5);
  static const tagHnbBg = Color(0xFFE8F8F0);
  static const tagHnbFg = Color(0xFF13714E);
  static const statusDot = Color(0xFF1CAF77);
  static const toast = Color(0xFF132945);
  static const noticeBg = Color(0xFFF7F9FD);
  static const choiceHover = Color(0xFFF6F9FF);
  static const choiceSelected = Color(0xFFEEF4FF);
  static const headerTh = Color(0xFFF8FAFF);
  static const headerThFg = Color(0xFF66748B);
  static const inputBorder = Color(0xFFD5DEEB);
  static const backdrop = Color(0xA60A1835);
  static const shadow = Color(0x0A1D3557);
  static const focusRing = Color(0x182463EB);
}

BoxDecoration panelDecoration({double radius = 16}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.line),
    boxShadow: const [
      BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 3)),
    ],
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      surface: Colors.white,
    ),
    splashColor: AppColors.focusRing,
    hoverColor: AppColors.choiceHover,
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
    ),
  );
}
