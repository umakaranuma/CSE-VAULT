import 'package:flutter/material.dart';

class AppColors {
  // ── Accent colors (same in both themes) ──
  static const em = Color(0xFF00FFA3);
  static const em2 = Color(0xFF00D988);
  static const em3 = Color(0xFF00B872);
  static const red = Color(0xFFFF4D6A);
  static const red2 = Color(0xFFFF2D4D);
  static const blue = Color(0xFF4D8FFF);
  static const gold = Color(0xFFFFC53D);

  // ── Dark theme ──
  static const bg = Color(0xFF060810);
  static const bg2 = Color(0xFF080B14);
  static const s1 = Color(0xFF0C0F1C);
  static const s2 = Color(0xFF101628);
  static const s3 = Color(0xFF151C32);
  static const s4 = Color(0xFF1A2238);
  static const s5 = Color(0xFF1F2840);
  static const glass = Color(0x0AFFFFFF);
  static const glass2 = Color(0x11FFFFFF);
  static const glass3 = Color(0x1CFFFFFF);
  static const border = Color(0x0FFFFFFF);
  static const border2 = Color(0x1AFFFFFF);
  static const border3 = Color(0x29FFFFFF);
  static const text = Color(0xFFF4F6FF);
  static const t2 = Color(0xFF8B95B8);
  static const t3 = Color(0xFF4A5270);
  static const t4 = Color(0xFF2E3554);
}

/// Context-aware colors that adapt to light/dark mode
class AC {
  final BuildContext _ctx;
  AC(this._ctx);

  bool get _dark => Theme.of(_ctx).brightness == Brightness.dark;

  // Backgrounds
  Color get bg => _dark ? AppColors.bg : const Color(0xFFF5F7FA);
  Color get card => _dark ? AppColors.glass : Colors.white;
  Color get cardElevated => _dark ? AppColors.s2 : Colors.white;

  // Borders
  Color get border => _dark ? AppColors.border2 : const Color(0x14000000);
  Color get borderLight => _dark ? AppColors.border : const Color(0x0A000000);

  // Text
  Color get textPrimary => _dark ? AppColors.text : const Color(0xFF1A1D2E);
  Color get textSecondary => _dark ? AppColors.t2 : const Color(0xFF6B7280);
  Color get textTertiary => _dark ? AppColors.t3 : const Color(0xFF9CA3AF);
  Color get textFaint => _dark ? AppColors.t4 : const Color(0xFFD1D5DB);

  // Surfaces
  Color get inputBg => _dark ? const Color(0x4D000000) : const Color(0xFFF0F2F5);
  Color get chipBg => _dark ? AppColors.glass : const Color(0xFFF0F2F5);
  Color get chipActiveBg => _dark ? const Color(0x1A00FFA3) : const Color(0x1A00C97D);
  Color get navBar => _dark ? const Color(0xD9060810) : const Color(0xF0FFFFFF);
  Color get dialogBg => _dark ? AppColors.s2 : Colors.white;
  Color get snackBg => _dark ? AppColors.s3 : Colors.black87;

  // Sheet
  Color get sheetTop => _dark ? AppColors.s2 : const Color(0xFFF8F9FB);
  Color get sheetBottom => _dark ? AppColors.s1 : Colors.white;
}

/// Shortcut: `final c = colors(context);`
AC colors(BuildContext context) => AC(context);
