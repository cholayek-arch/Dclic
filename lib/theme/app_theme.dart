import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      brightness: Brightness.light,
    );

    final emojiFallbacks = [
      'Segoe UI Emoji', // Windows
      'Apple Color Emoji', // iOS/macOS
      'Noto Color Emoji', // Android/Linux
    ];

    final text = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontSize: 34, 
        fontWeight: FontWeight.w700,
        fontFamilyFallback: emojiFallbacks,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 24, 
        fontWeight: FontWeight.w700,
        fontFamilyFallback: emojiFallbacks,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 18, 
        fontWeight: FontWeight.w600,
        fontFamilyFallback: emojiFallbacks,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: 16, 
        height: 1.4,
        fontFamilyFallback: emojiFallbacks,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14, 
        height: 1.3,
        fontFamilyFallback: emojiFallbacks,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 14, 
        fontWeight: FontWeight.w600,
        fontFamilyFallback: emojiFallbacks,
      ),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
