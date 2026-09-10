import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IndustrialLoaderOverlay extends StatefulWidget {
  final String title;
  final String? message;

  const IndustrialLoaderOverlay({
    super.key,
    this.title = 'PROVISIONING INDUSTRIAL NODE',
    this.message = 'Synchronizing telemetry parameters...',
  });

  @override
  State<IndustrialLoaderOverlay> createState() => _IndustrialLoaderOverlayState();
}

class _IndustrialLoaderOverlayState extends State<IndustrialLoaderOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(160),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF141618),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00E5FF).withAlpha(100), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withAlpha(40),
                blurRadius: 30,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom Industrial Tech Gauge Spinner
              SizedBox(
                width: 90,
                height: 90,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _IndustrialSpinnerPainter(progress: _controller.value),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                widget.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle Message
              if (widget.message != null && widget.message!.isNotEmpty)
                Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00E5FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 16),

              // Status Indicator Dot
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E5FF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00E5FF),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE SYNC ACTIVE',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndustrialSpinnerPainter extends CustomPainter {
  final double progress;

  _IndustrialSpinnerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Outer Background Track
    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, bgPaint);

    // Rotating Glowing Cyan Arc
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0x0000E5FF),
          Color(0x8000E5FF),
          Color(0xFF00E5FF),
        ],
        stops: const [0.0, 0.7, 1.0],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;

    final startAngle = progress * 2 * math.pi;
    const sweepAngle = math.pi * 1.3;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Inner Counter-Rotating Ring
    final innerPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final innerRadius = radius - 12;
    final innerStartAngle = -progress * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      innerStartAngle,
      math.pi * 0.8,
      false,
      innerPaint,
    );

    // Center Pulse Node
    final centerPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4 + (math.sin(progress * math.pi * 2) * 1.5), centerPaint);
  }

  @override
  bool shouldRepaint(covariant _IndustrialSpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

void showIndustrialLoader(BuildContext context, {String title = 'PROVISIONING INDUSTRIAL NODE', String? message}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => IndustrialLoaderOverlay(title: title, message: message),
  );
}

void hideIndustrialLoader(BuildContext context) {
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
