import 'package:flutter/material.dart';

/// RNF-006 — suporte a modo escuro e a Dynamic Type (o Flutter já escala o
/// texto automaticamente com base em `MediaQuery.textScaler`; nunca
/// travamos esse fator nos temas abaixo).
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2F5597));
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2F5597),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.dark,
    );
  }
}
