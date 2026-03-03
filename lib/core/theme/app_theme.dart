import 'package:flutter/material.dart';

class AppTheme {
  // Light palette
  static const Color _primary = Color(0xFF5C6BC0); // indigo
  static const Color _primaryDark = Color(0xFF3949AB);
  static const Color _accent = Color(0xFF7E57C2); // purple accent
  static const Color _bg = Color(0xFFF4F6FB); // light grey-white
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF5A6275);

  // Keep dark palette constants so nothing else breaks
  static const Color _deepSpace = Color(0xFF0A0E1A);
  static const Color _spaceBlue = Color(0xFF0D1B2A);
  static const Color _nebulaPurple = Color(0xFF6C63FF);
  static const Color _silver = Color(0xFFB0BEC5);
  static const Color _brightSilver = Color(0xFFE0E6ED);
  static const Color _starWhite = Color(0xFFF0F4FF);
  static const Color _surfaceCard = Color(0xFF141E30);
  static const Color _surfaceVariant = Color(0xFF1C2A3A);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.light(
          brightness: Brightness.light,
          primary: _primary,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFE8EAF6),
          onPrimaryContainer: _primaryDark,
          secondary: _accent,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFEDE7F6),
          onSecondaryContainer: Color(0xFF4527A0),
          surface: _surface,
          onSurface: _onSurface,
          surfaceContainerHighest: Color(0xFFEEF0F8),
          onSurfaceVariant: _textSecondary,
          outline: Color(0xFFBDBDBD),
          outlineVariant: Color(0xFFE0E0E0),
          error: Color(0xFFD32F2F),
          onError: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _surface,
          foregroundColor: _onSurface,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: _onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          iconTheme: IconThemeData(color: _textSecondary),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 3,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE0E0E0),
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: _textSecondary),
          hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: _onSurface, fontWeight: FontWeight.w600),
          titleMedium:
              TextStyle(color: _onSurface, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: _onSurface, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: _onSurface),
          bodyMedium: TextStyle(color: _textSecondary),
          bodySmall: TextStyle(color: _textSecondary),
          labelLarge: TextStyle(color: _onSurface, fontWeight: FontWeight.w500),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFFE8EAF6);
              }
              return _surface;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return _primary;
              return _textSecondary;
            }),
            side: WidgetStateProperty.all(
              const BorderSide(color: Color(0xFFBDBDBD)),
            ),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _primary;
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: const BorderSide(color: Color(0xFFBDBDBD), width: 1.5),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _primary;
            return Colors.white;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFE8EAF6);
            }
            return const Color(0xFFBDBDBD);
          }),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _deepSpace,
        colorScheme: const ColorScheme.dark(
          brightness: Brightness.dark,
          primary: _nebulaPurple,
          onPrimary: _starWhite,
          primaryContainer: Color(0xFF1E1A3A),
          onPrimaryContainer: _brightSilver,
          secondary: _silver,
          onSecondary: _deepSpace,
          secondaryContainer: _surfaceVariant,
          onSecondaryContainer: _brightSilver,
          surface: _spaceBlue,
          onSurface: _brightSilver,
          surfaceContainerHighest: _surfaceCard,
          onSurfaceVariant: _silver,
          outline: Color(0xFF445566),
          outlineVariant: Color(0xFF2A3A4A),
          error: Color(0xFFFF6B8A),
          onError: _deepSpace,
        ),
        cardTheme: CardThemeData(
          color: _surfaceCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF1E3050), width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _deepSpace,
          foregroundColor: _brightSilver,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: _brightSilver,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: _silver),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _spaceBlue,
          indicatorColor: const Color(0xFF2A1E5A),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: _nebulaPurple);
            }
            return const IconThemeData(color: _silver);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: _nebulaPurple,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(color: _silver, fontSize: 12);
          }),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _nebulaPurple,
          foregroundColor: _starWhite,
          elevation: 4,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF1E3050),
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A3A4A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A3A4A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _nebulaPurple, width: 1.5),
          ),
          labelStyle: const TextStyle(color: _silver),
          hintStyle: TextStyle(color: _silver.withValues(alpha: 0.5)),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: _starWhite, fontWeight: FontWeight.w600),
          titleMedium:
              TextStyle(color: _brightSilver, fontWeight: FontWeight.w500),
          titleSmall:
              TextStyle(color: _brightSilver, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: _brightSilver),
          bodyMedium: TextStyle(color: _silver),
          bodySmall: TextStyle(color: _silver),
          labelLarge:
              TextStyle(color: _brightSilver, fontWeight: FontWeight.w500),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF2A1E5A);
              }
              return _surfaceCard;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _nebulaPurple;
              }
              return _silver;
            }),
            side: WidgetStateProperty.all(
              const BorderSide(color: Color(0xFF2A3A4A)),
            ),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _nebulaPurple;
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(_starWhite),
          side: const BorderSide(color: _silver, width: 1.5),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _nebulaPurple;
            return _silver;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF2A1E5A);
            }
            return _surfaceVariant;
          }),
        ),
      );
}
