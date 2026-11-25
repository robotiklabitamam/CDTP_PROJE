import 'package:material_ui/material_ui.dart';

/// YTÜ logosundan alınan kurumsal renkler.
abstract final class YtuColors {
  /// Logodaki lacivert (#222B57).
  static const navy = Color(0xFF222B57);
  static const navyDark = Color(0xFF171D3D);

  /// Logodaki altın (#AC966E).
  static const gold = Color(0xFFAC966E);
  static const goldLight = Color(0xFFF1ECE2);

  static const background = Color(0xFFF7F6F2);
  static const textMuted = Color(0xFF6B6F80);
  static const stale = Color(0xFF9EA1AD);

  static const ok = Color(0xFF2E7D32);
  static const warning = Color(0xFFE67E00);
  static const danger = Color(0xFFC62828);
}

ThemeData buildYtuTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: YtuColors.navy).copyWith(
    primary: YtuColors.navy,
    onPrimary: Colors.white,
    secondary: YtuColors.gold,
    // Altın üzerinde beyaz yazı kontrastı zayıf; lacivert kullanılır.
    onSecondary: YtuColors.navy,
    surface: Colors.white,
    error: YtuColors.danger,
  );

  // Metin stilleri platformun tipografisinden türetilir (iOS'ta SF, Android'de Roboto).
  final text = ThemeData(useMaterial3: true, colorScheme: scheme).textTheme;
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  final buttonText = text.labelLarge!.copyWith(fontWeight: FontWeight.w600, fontSize: 15);
  final chipText = text.labelLarge!.copyWith(fontWeight: FontWeight.w600);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: YtuColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: YtuColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE6E2D8)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: YtuColors.navy,
        foregroundColor: Colors.white,
        shape: buttonShape,
        padding: buttonPadding,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: YtuColors.navy,
        side: const BorderSide(color: YtuColors.gold, width: 1.6),
        shape: buttonShape,
        padding: buttonPadding,
        textStyle: buttonText,
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: YtuColors.navy,
      backgroundColor: Colors.white,
      side: const BorderSide(color: YtuColors.gold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: chipText.copyWith(color: YtuColors.navy),
      secondaryLabelStyle: chipText.copyWith(color: Colors.white),
      checkmarkColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: YtuColors.gold.withValues(alpha: 0.35),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? YtuColors.navy : YtuColors.textMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium!.copyWith(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? YtuColors.navy : YtuColors.textMuted,
        ),
      ),
    ),
  );
}

/// Sayaçlar ve ölçüm değerleri için sabit genişlikli rakamlar.
const tabularFigures = [FontFeature.tabularFigures()];
