import 'package:flutter/material.dart';

/// Pure domain enum describing the category a [Task] belongs to.
///
/// Kept free of any persistence or UI framework coupling beyond the
/// presentation helpers (color/icon) which are convenient constants.
enum TaskCategory {
  work,
  personal,
  urgent,
  shopping,
  other;

  /// Stable string used for persistence. Never localise this value.
  String get storageKey => name;

  /// Human readable label for the UI.
  String get label {
    switch (this) {
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.urgent:
        return 'Urgent';
      case TaskCategory.shopping:
        return 'Shopping';
      case TaskCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.work:
        return Icons.work_outline;
      case TaskCategory.personal:
        return Icons.person_outline;
      case TaskCategory.urgent:
        return Icons.priority_high;
      case TaskCategory.shopping:
        return Icons.shopping_bag_outlined;
      case TaskCategory.other:
        return Icons.label_outline;
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.work:
        return const Color(0xFF4C6FFF);
      case TaskCategory.personal:
        return const Color(0xFF1BBF8E);
      case TaskCategory.urgent:
        return const Color(0xFFFF5A5F);
      case TaskCategory.shopping:
        return const Color(0xFFFFA62B);
      case TaskCategory.other:
        return const Color(0xFF9B8AFB);
    }
  }

  static TaskCategory fromStorage(String? value) {
    return TaskCategory.values.firstWhere(
      (c) => c.storageKey == value,
      orElse: () => TaskCategory.other,
    );
  }
}

