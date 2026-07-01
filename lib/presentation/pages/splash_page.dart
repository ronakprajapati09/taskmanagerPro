import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Splash screen matching the design:
///  • Deep navy-purple gradient background
///  • Faint ghost icons in corners (checkbox, calendar, filter, bell)
///  • Large circular glow ring behind the app icon
///  • App icon (todoappicon.png) inside a rounded-square card
///  • "Task Manager Pro" – "Pro" in purple gradient
///  • Tagline: "Organize. Prioritize. Achieve."
///  • Three feature tiles: Manage Tasks | Track Progress | Reminders & Notifications
///  • Animated progress bar with percentage + "Preparing your tasks…"
class SplashPage extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashPage({super.key, required this.onComplete});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // bg fade
  late final Animation<double> _bgFade;
  // icon
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  // glow ring
  late final Animation<double> _ringScale;
  late final Animation<double> _ringFade;
  // title
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  // tagline
  late final Animation<double> _tagFade;
  // feature row
  late final Animation<double> _featuresFade;
  late final Animation<Offset> _featuresSlide;
  // progress bar
  late final Animation<double> _progressFade;
  late final Animation<double> _progressValue;
  // exit
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // Total: 3 200 ms
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _bgFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.00, 0.12, curve: Curves.easeIn),
    );

    _ringScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.05, 0.30, curve: Curves.easeOutBack),
      ),
    );
    _ringFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.05, 0.25, curve: Curves.easeIn),
    );

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.10, 0.38, curve: _BounceCurve()),
      ),
    );
    _iconFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.10, 0.24, curve: Curves.easeIn),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.50, curve: Curves.easeOutCubic),
    ));
    _titleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.48, curve: Curves.easeIn),
    );

    _tagFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.44, 0.58, curve: Curves.easeIn),
    );

    _featuresSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.52, 0.68, curve: Curves.easeOutCubic),
    ));
    _featuresFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.52, 0.68, curve: Curves.easeIn),
    );

    _progressFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.60, 0.72, curve: Curves.easeIn),
    );
    _progressValue = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.62, 0.82, curve: Curves.easeInOut),
      ),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.88, 1.00, curve: Curves.easeInCubic),
      ),
    );

    _ctrl.forward().whenCompleteOrCancel(() {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Opacity(
          opacity: _exitFade.value,
          child: Scaffold(
            backgroundColor: const Color(0xFF060B1E),
            body: FadeTransition(
              opacity: _bgFade,
              child: _Background(
                child: SafeArea(
                  child: Stack(
                    children: [
                      // Ghost icons in corners
                      const _GhostIcons(),

                      // Main content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            const Spacer(flex: 2),

                            // ── Glow ring + App icon ──────────────────────
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Glow rings
                                  Opacity(
                                    opacity: _ringFade.value,
                                    child: Transform.scale(
                                      scale: _ringScale.value,
                                      child: _GlowRing(size: 210),
                                    ),
                                  ),

                                  // App icon card
                                  Opacity(
                                    opacity: _iconFade.value,
                                    child: Transform.scale(
                                      scale: _iconScale.value,
                                      child: _IconCard(),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ── Title ─────────────────────────────────────
                            SlideTransition(
                              position: _titleSlide,
                              child: FadeTransition(
                                opacity: _titleFade,
                                child: const _Title(),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // ── Divider dot ───────────────────────────────
                            FadeTransition(
                              opacity: _titleFade,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF7B5FD4),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ── Tagline ───────────────────────────────────
                            FadeTransition(
                              opacity: _tagFade,
                              child: const Text(
                                'Organize. Prioritize. Achieve.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFFAEB8D0),
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 36),

                            // ── Feature row ───────────────────────────────
                            SlideTransition(
                              position: _featuresSlide,
                              child: FadeTransition(
                                opacity: _featuresFade,
                                child: const _FeatureRow(),
                              ),
                            ),

                            const Spacer(flex: 2),

                            // ── Progress ──────────────────────────────────
                            FadeTransition(
                              opacity: _progressFade,
                              child: _ProgressSection(
                                  value: _progressValue.value),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  final Widget child;
  const _Background({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0E2A),
            Color(0xFF0D1235),
            Color(0xFF120D3A),
            Color(0xFF0A0818),
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ghost icons (corner decorations)
// ─────────────────────────────────────────────────────────────────────────────

class _GhostIcons extends StatelessWidget {
  const _GhostIcons();

  @override
  Widget build(BuildContext context) {
    const color = Color(0x22FFFFFF);
    const size = 36.0;
    return Stack(
      children: [
        // Top-left: checkbox
        Positioned(
          top: 48,
          left: 24,
          child: _GhostIcon(icon: Icons.check_box_outlined, size: size, color: color),
        ),
        // Top-right: calendar
        Positioned(
          top: 48,
          right: 24,
          child: _GhostIcon(icon: Icons.calendar_month_outlined, size: size, color: color),
        ),
        // Middle-left: filter
        Positioned(
          top: 280,
          left: 16,
          child: _GhostIcon(icon: Icons.filter_alt_outlined, size: size, color: color),
        ),
        // Middle-right: bell
        Positioned(
          top: 300,
          right: 16,
          child: _GhostIcon(icon: Icons.notifications_outlined, size: size, color: color),
        ),
      ],
    );
  }
}

class _GhostIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  const _GhostIcon({required this.icon, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: size * 0.7),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glow ring
// ─────────────────────────────────────────────────────────────────────────────

class _GlowRing extends StatelessWidget {
  final double size;
  const _GlowRing({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RingPainter()),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0x334C6FFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawCircle(center, radius, glowPaint);

    // Solid ring gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final ringPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF4C6FFF),
          Color(0xFFAA55FF),
          Color(0xFFFF3CAC),
          Color(0xFF4C6FFF),
        ],
        stops: [0.0, 0.35, 0.70, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon card
// ─────────────────────────────────────────────────────────────────────────────

class _IconCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2D6B), Color(0xFF121A42)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C6FFF).withAlpha(100),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF2E3E80),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(22),
      child: Image.asset(
        'assets/todoappicon.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Title
// ─────────────────────────────────────────────────────────────────────────────

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final proPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7B5FD4), Color(0xFFAA7FFF)],
      ).createShader(const Rect.fromLTWH(0, 0, 80, 40));

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Task Manager ',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          TextSpan(
            text: 'Pro',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              foreground: proPaint,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature row
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FeatureTile(
            icon: Icons.assignment_outlined,
            label: 'Manage\nTasks',
            iconColor: const Color(0xFF6B8AFF),
          ),
          _VerticalDivider(),
          _FeatureTile(
            customLabel: '75%',
            isPercentage: true,
            label: 'Track\nProgress',
            iconColor: const Color(0xFF6B8AFF),
          ),
          _VerticalDivider(),
          _FeatureTile(
            icon: Icons.notifications_outlined,
            label: 'Reminders &\nNotifications',
            iconColor: const Color(0xFFFFB347),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      color: const Color(0x33FFFFFF),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData? icon;
  final String? customLabel;
  final bool isPercentage;
  final String label;
  final Color iconColor;

  const _FeatureTile({
    this.icon,
    this.customLabel,
    this.isPercentage = false,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon or percentage circle
          if (isPercentage)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: iconColor, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                customLabel!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
            )
          else
            Icon(icon, color: iconColor, size: 32),

          const SizedBox(height: 8),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB0BDD4),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress section
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final double value; // 0.0 – 1.0
  const _ProgressSection({required this.value});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Preparing your tasks...',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFB0BDD4),
              ),
            ),
            Text(
              '$pct%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB0BDD4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                // Track
                Container(color: const Color(0xFF1C2340)),
                // Fill
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4C6FFF), Color(0xFFAA55FF)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bounce curve
// ─────────────────────────────────────────────────────────────────────────────

class _BounceCurve extends Curve {
  const _BounceCurve();

  @override
  double transformInternal(double t) {
    const c4 = (2 * math.pi) / 3;
    if (t == 0) return 0;
    if (t == 1) return 1;
    return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1;
  }
}
