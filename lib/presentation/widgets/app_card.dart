import 'package:flutter/material.dart';

/// A styled surface used throughout the app. Implemented with [Material]
/// instead of relying on [ThemeData.cardTheme] so the code compiles across a
/// wide range of Flutter SDK versions (the `cardTheme` field type changed
/// between releases).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF171C24) : Colors.white;
    final body = padding == null ? child : Padding(padding: padding!, child: child);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}
