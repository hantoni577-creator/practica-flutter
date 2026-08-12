import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primario = Color(0xFF1B1B2F);
  static const Color acento = Color(0xFFF39C12);
  static const Color fondo = Color(0xFFF5F5F5);
  static const Color textoSecundario = Color(0xFF6B6B6B);
  static const Color peligro = Color(0xFFC62828);
  static const Color exito = Color(0xFF2E7D32);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: acento,
          primary: primario,
          secondary: acento,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: fondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: primario,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: acento, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primario,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFFDE9C8),
        ),
        dividerTheme:
            const DividerThemeData(color: Color(0xFFE0E0E0), thickness: 1),
      );
}
