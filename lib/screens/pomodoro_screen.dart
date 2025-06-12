import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PomodoroScreen extends StatefulWidget {
  final int secondsRemaining;
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  static const int totalSeconds = 25 * 60;

  const PomodoroScreen({
    super.key,
    required this.secondsRemaining,
    required this.isRunning,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressAnimationController;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // Rotación continua
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    super.dispose();
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final targetProgress =
        1.0 - (widget.secondsRemaining / PomodoroScreen.totalSeconds);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color.fromARGB(37, 0, 0, 0),
                  width: 0.9,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  "Estudio",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/svg/notification_icon.svg',
                    width: 26,
                    height: 26,
                    colorFilter: const ColorFilter.mode(
                      Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/svg/settings_icon.svg',
                    width: 26,
                    height: 26,
                    colorFilter: const ColorFilter.mode(
                      Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xF0E8F1FF),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      'assets/svg/user_icon.svg',
                      width: 26,
                      height: 26,
                      colorFilter: const ColorFilter.mode(
                        Colors.blue,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Circular Timer
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _progressAnimationController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(220, 220),
                        painter: _AnimatedCirclePainter(
                          progress: targetProgress,
                          rotation: _progressAnimationController.value,
                        ),
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(
                            child: Text(
                              formatTime(widget.secondsRemaining),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon:
                            widget.isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                        color: Colors.lightBlue,
                        onPressed:
                            widget.isRunning ? widget.onPause : widget.onStart,
                      ),
                      const SizedBox(width: 12),
                      _buildControlButton(
                        icon: Icons.stop_rounded,
                        color: Colors.redAccent,
                        onPressed: widget.onReset,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 46),
        onPressed: onPressed,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
    );
  }
}

class _AnimatedCirclePainter extends CustomPainter {
  final double progress;
  final double rotation;

  _AnimatedCirclePainter({required this.progress, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    final backgroundPaint =
        Paint()
          ..color = const Color(0xFFF5F5F5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    final sweepAngle = 2 * pi * progress;

    final shaderPaint =
        Paint()
          ..shader = SweepGradient(
            startAngle: 0,
            endAngle: 2 * pi,
            tileMode: TileMode.repeated,
            transform: GradientRotation(2 * pi * rotation),
            colors: const [
              Colors.lightBlueAccent,
              Colors.deepPurpleAccent,
              Colors.lightBlueAccent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      shaderPaint,
    );
  }

  @override
  bool shouldRepaint(_AnimatedCirclePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.rotation != rotation;
}
