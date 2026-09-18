import 'package:flutter/material.dart';

/// Палитра приложения: яркая, тёплая, дружелюбная к детям.
class AppColors {
  static const Color bg = Color(0xFFFFF6EE);
  static const Color bgDeep = Color(0xFFFFE9D2);
  static const Color primary = Color(0xFFFF6B6B);
  static const Color primaryDark = Color(0xFFE85555);
  static const Color secondary = Color(0xFF4ECDC4);
  static const Color accent = Color(0xFFFFD93D);
  static const Color grape = Color(0xFFA66CFF);
  static const Color leaf = Color(0xFF6BCB77);
  static const Color sky = Color(0xFF4D96FF);
  static const Color ink = Color(0xFF2D2A32);
  static const Color inkSoft = Color(0xFF6E6A76);
  static const Color card = Colors.white;
  static const Color coin = Color(0xFFFFB300);
}

/// Готовая тема Material 3.
class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.grape,
      onTertiary: Colors.white,
      surface: AppColors.bg,
      onSurface: AppColors.ink,
      surfaceContainerHighest: Colors.white,
      onSurfaceVariant: AppColors.inkSoft,
      error: AppColors.primaryDark,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      // Лейблы зафиксированы в 12px для обоих состояний: в M3 выбранная
      // вкладка по умолчанию растёт до 14px и на узком экране (6 вкладок,
      // 360 dp) мог бы не влезти длинный лейбл («Кошелёк»). Фиксированный
      // размер убирает этот риск (ТЗ §10, мин. ширина 360 dp).
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.inkSoft,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: AppColors.primary),
      dividerTheme: DividerThemeData(color: Colors.black12),
    );
  }
}
