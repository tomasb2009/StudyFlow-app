import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../background_task.dart';
import '../models/pomodoro_stats.dart';

class PomodoroScreen extends StatefulWidget {
  final int initialRemaining;
  final bool initialIsRunning;
  final bool initialServiceRunning;
  final Function(int, bool, bool) onStateChanged;

  const PomodoroScreen({
    super.key,
    required this.initialRemaining,
    required this.initialIsRunning,
    required this.initialServiceRunning,
    required this.onStateChanged,
  });

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late int _remaining;
  late bool _isRunning;
  late bool _isServiceRunning;
  PomodoroStats? _stats;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _remaining = widget.initialRemaining;
    _isRunning = widget.initialIsRunning;
    _isServiceRunning = widget.initialServiceRunning;

    _initializeAsync();
    FlutterForegroundTask.addTaskDataCallback(_onData);
    _loadStats();
  }

  Future<void> _initializeAsync() async {
    await _requestPermissions();

    if (_isServiceRunning) {
      FlutterForegroundTask.sendDataToTask({"action": "getState"});
    }

    // Verificar el estado del servicio al inicializar
    _checkServiceStatus();
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    print(
      '🔍 Estado del servicio de background: ${isRunning ? "ACTIVO" : "INACTIVO"}',
    );

    if (mounted) {
      setState(() {
        _isServiceRunning = isRunning;
      });
    }
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    FlutterForegroundTask.removeTaskDataCallback(_onData);
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      if (!await FlutterForegroundTask.canScheduleExactAlarms) {
        await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      }
    }
  }

  void _updateState(int remaining, bool isRunning, bool serviceRunning) {
    if (!mounted) return;
    setState(() {
      _remaining = remaining;
      _isRunning = isRunning;
      _isServiceRunning = serviceRunning;
    });
    widget.onStateChanged(remaining, isRunning, serviceRunning);
  }

  void _onData(Object data) {
    if (!mounted) return;

    if (data is Map) {
      if (data.containsKey("remaining")) {
        print(
          '📱 Recibido estado del background: remaining=${data["remaining"]}, isRunning=${data["isRunning"]}',
        );
        _updateState(data["remaining"], data["isRunning"], _isServiceRunning);
      } else if (data.containsKey("action") &&
          data["action"] == "stateUpdate") {
        _updateState(data["remaining"], data["isRunning"], _isServiceRunning);
      } else if (data.containsKey("action") &&
          data["action"] == "serviceStopped") {
        // El servicio se ha detenido
        _updateState(_remaining, false, false);
      } else if (data["action"] == "pomodoroStats" && data["stats"] != null) {
        setState(() {
          _stats = PomodoroStats.fromJson(data["stats"]);
        });
      }
    }
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _toggle() async {
    print(
      '🔄 Botón toggle presionado - Estado actual: ${_isRunning ? "Corriendo" : "Pausado"}, Servicio: ${_isServiceRunning ? "Activo" : "Inactivo"}',
    );

    if (!_isServiceRunning) {
      print('🚀 Iniciando servicio de background task...');

      // Guardar el estado inicial antes de iniciar el servicio
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('remaining', _remaining);
      await prefs.setBool('isRunning', true);

      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: '🧠 StudyFlow - Pomodoro Activo',
        notificationText: '⏳ Restan: ${formatTime(_remaining)}',
        notificationIcon: const NotificationIcon(
          metaDataName: 'com.example.studyflow_app.service.HEART_ICON',
        ),
        notificationButtons: [
          const NotificationButton(id: 'pause_resume', text: 'Pausar'),
        ],
        callback: startCallback,
      );

      // Esperar a que el servicio realmente esté activo
      bool started = false;
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        started = await FlutterForegroundTask.isRunningService;
        if (started) break;
      }
      if (!mounted) return;
      if (started) {
        print('✅ Servicio iniciado correctamente');
        // Enviar el estado inicial al background task
        FlutterForegroundTask.sendDataToTask({
          "action": "start",
          "remaining": _remaining,
          "isRunning": true,
        });
        // NO actualizar la UI aquí, esperar a que el background task confirme
        setState(() {
          _isServiceRunning = true;
        });
      } else {
        print('❌ No se pudo iniciar el servicio');
        _updateState(_remaining, false, false);
      }
    } else {
      if (_isRunning) {
        // Si está corriendo, pausar
        print('⏸️ Pausando pomodoro...');
        FlutterForegroundTask.sendDataToTask({"action": "pause"});
        if (!mounted) return;
        _updateState(_remaining, false, true);
      } else {
        // Si está pausado, reanudar
        print('▶️ Reanudando pomodoro...');
        FlutterForegroundTask.sendDataToTask({"action": "pause"});
        if (!mounted) return;
        _updateState(_remaining, true, true);
      }
    }
  }

  Future<void> _reset() async {
    print('🛑 Botón reset presionado - Estado actual: ${_isRunning ? "Corriendo" : "Pausado"}, Servicio: ${_isServiceRunning ? "Activo" : "Inactivo"}');
    
    if (_isServiceRunning) {
      print('🔄 Enviando acción RESET al background task...');
      FlutterForegroundTask.sendDataToTask({"action": "reset"});
      
      // Esperar un poco para que el background task procese el reset
      await Future.delayed(const Duration(milliseconds: 200));
      
      print('🛑 Deteniendo servicio de background task...');
      await FlutterForegroundTask.stopService();
      print('✅ Servicio detenido correctamente');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('remaining', 25 * 60);
    await prefs.setBool('isRunning', false);
    print('💾 Estado reseteado en SharedPreferences');

    if (!mounted) return;
    
    // Actualizar la UI inmediatamente
    setState(() {
      _remaining = 25 * 60;
      _isRunning = false;
      _isServiceRunning = false;
    });
    
    print('✅ UI reseteada a 25:00 - Estado: Pausado, Servicio: Inactivo');
    
    // Notificar el cambio de estado
    widget.onStateChanged(_remaining, _isRunning, _isServiceRunning);
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString('pomodoro_stats');
    setState(() {
      if (statsJson != null) {
        _stats = PomodoroStats.fromJson(statsJson);
      } else {
        _stats = PomodoroStats(dailySeconds: {});
      }
    });
  }

  Future<void> _debugPrintStats() async {
    // Pedir los stats actuales al background
    FlutterForegroundTask.sendDataToTask({"action": "getStats"});
    // Esperar un poco a que lleguen los datos
    await Future.delayed(const Duration(milliseconds: 120));
    final last7 = _stats?.getLast7Days() ?? {};
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    print('⏱️ Pomodoro stats últimos 7 días:');
    last7.forEach((k, v) {
      final date = DateTime.tryParse(k);
      String weekday = '';
      if (date != null) {
        weekday = dias[(date.weekday - 1) % 7];
      }
      print('  $k ($weekday): ${v ~/ 60} min (${v}s)');
    });
    print('Hoy es: ${DateTime.now()} (weekday: ${dias[(DateTime.now().weekday - 1) % 7]})');
  }

  @override
  Widget build(BuildContext context) {
    final targetProgress = 1.0 - (_remaining / (25 * 60));
    final screenWidth = MediaQuery.of(context).size.width;
    final circleSize = screenWidth * 0.7;

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
                // Indicador del estado del servicio
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isServiceRunning
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isServiceRunning ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isServiceRunning ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isServiceRunning
                            ? 'Servicio Activo'
                            : 'Servicio Inactivo',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isServiceRunning ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
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
                        size: Size(circleSize, circleSize),
                        painter: _AnimatedCirclePainter(
                          progress: targetProgress,
                          rotation: _progressAnimationController.value,
                        ),
                        child: SizedBox(
                          width: circleSize,
                          height: circleSize,
                          child: Center(
                            child: Text(
                              formatTime(_remaining),
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
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon:
                            _isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                        color: Colors.lightBlue,
                        onPressed: _toggle,
                      ),
                      const SizedBox(width: 20),
                      _buildControlButton(
                        icon: Icons.stop_rounded,
                        color: Colors.redAccent,
                        onPressed: _reset,
                      ),
                      const SizedBox(width: 20),
                      // Botón de debug para imprimir stats
                      _buildControlButton(
                        icon: Icons.bug_report,
                        color: Colors.deepPurple,
                        onPressed: _debugPrintStats,
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
      padding: const EdgeInsets.all(10),
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
    final strokeWidth = 20.0;
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
