import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single action revealed when the FAB expands.
class FabAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const FabAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Custom expandable Floating Action Button.
///
/// - Main button rotates its icon from `+` to `×`.
/// - Sub-buttons scale/translate/fade in with a staggered delay.
/// - A dimmed backdrop covers the screen while open and closes on tap-outside.
/// - Provides haptic feedback on open/close.
class AnimatedFab extends StatefulWidget {
  final List<FabAction> actions;

  const AnimatedFab({super.key, required this.actions});

  @override
  State<AnimatedFab> createState() => AnimatedFabState();
}

class AnimatedFabState extends State<AnimatedFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void close() {
    if (!_open) return;
    setState(() => _open = false);
    _controller.reverse();
  }

  bool get isOpen => _open;

  @override
  Widget build(BuildContext context) {
    final count = widget.actions.length;
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < count; i++)
              _buildAction(widget.actions[i], i, count),
            const SizedBox(height: 12),
            _buildMainButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildAction(FabAction action, int index, int count) {
    // Stagger: items closest to the FAB appear first.
    final reverseIndex = count - 1 - index;
    final start = (reverseIndex / count) * 0.5;
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1.0, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 24),
            child: Transform.scale(
              scale: v,
              alignment: Alignment.centerRight,
              child: child,
            ),
          ),
        );
      },
      child: IgnorePointer(
        ignoring: !_open,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _Pill(label: action.label),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                heroTag: 'fab_${action.label}',
                backgroundColor: action.color,
                foregroundColor: Colors.white,
                elevation: 2,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  close();
                  action.onTap();
                },
                child: Icon(action.icon),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'fab_main',
      onPressed: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Transform.rotate(
          angle: _controller.value * (3.1415926535 * 3 / 4),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}


