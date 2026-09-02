import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Colores base de la web
  static const Color bgMain = Color(0xFF0A0A0A);
  static const Color bgCard = Color(0xFF141414);
  static const Color bgInput = Color(0xFF1F1F1F);
  static const Color borderColor = Color(0xFF2D2D2D);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF666666);

  static const Color colorSuccess = Color(0xFF2ECC71);
  static const Color colorError = Color(0xFFE74C3C);
  static const Color colorWarning = Color(0xFFF1C40F);

  // ==========================================
  // AQUÍ HACES EL CAMBIO:
  // ==========================================
// En tu archivo AppTheme:
  static const Color primario = Color(0xFF1F1F1F);
  static const Color bgCirculo = Color(0xFF1F1F1F);
  static const Color acento = Color(0xFFF1C40F);
  static const Color fondo = bgMain;
  static const Color textoSecundario = textSecondary;
  static const Color peligro = colorError;
  static const Color exito = colorSuccess;

  // ... resto de tu código get dark / get light
  // ==========================================================================
  // 3. GETTERS DEL TEMA (Soporta AppTheme.dark y AppTheme.light)
  // ==========================================================================
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgMain,
    colorScheme: const ColorScheme.dark(
      primary: textPrimary,
      surface: bgCard,
      error: colorError,
      onPrimary: Colors.black,
      onSurface: textPrimary,
    ),
    fontFamily: 'Segoe UI',

    // Header / AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000),
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      shape: Border(
        bottom: BorderSide(color: borderColor, width: 1),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: textPrimary,
      ),
    ),

    // Paneles, cards y contenedores
    cardTheme: const CardThemeData(
      elevation: 0,
      color: bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: borderColor, width: 1),
      ),
    ),

    // Campos de texto (inputs)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgInput,
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 12,
        letterSpacing: 1,
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: textSecondary, width: 1.5),
      ),
    ),

    // Botones principales (.btn-submit)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: textPrimary,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(48),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // Botones secundarios / login
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: bgInput,
        foregroundColor: textSecondary,
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        textStyle: const TextStyle(fontSize: 14),
      ),
    ),

    // Tablas y divisores
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 1,
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(bgCard),
      headingTextStyle: const TextStyle(
        color: textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      dataTextStyle: const TextStyle(
        color: textPrimary,
        fontSize: 14,
      ),
      dividerThickness: 1,
    ),
  );

  // Redirige 'light' hacia el tema dark para evitar editar app.dart línea 31
  static ThemeData get light => dark;
}
