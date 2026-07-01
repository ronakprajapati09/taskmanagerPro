import 'package:flutter/material.dart';

/// Content for the swipe-to-delete undo snackbar. Shows a visible countdown
/// ring + number that ticks down across [duration] and an Undo button.
class UndoCountdownContent extends StatefulWidget {
  final String taskTitle;
  final Duration duration;
  final VoidCallback onUndo;

  const UndoCountdownContent({
    super.key,
    required this.taskTitle,
    required this.duration,
    required this.onUndo,
  });

  @override
  State<UndoCountdownContent> createState() => _UndoCountdownContentState();
}

class _UndoCountdownContentState extends State<UndoCountdownContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.duration.inSeconds;
    return Row(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final remaining =
                (totalSeconds - (_controller.value * totalSeconds))
                    .ceil()
                    .clamp(0, totalSeconds);
            return SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 1 - _controller.value,
                    strokeWidth: 3,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  Text(
                    '$remaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Deleted "${widget.taskTitle}"',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: widget.onUndo,
          style: TextButton.styleFrom(
            foregroundColor: Colors.amberAccent,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: const Text('UNDO'),
        ),
      ],
    );
  }
}

