import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../background_task.dart';

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

  // Nuevas variables para manejar la duración seleccionada
  int _selectedDuration = 25; // minutos
  final List<int> _availableDurations = [25, 50, 90];

  // Bandera para evitar conflictos durante el reset
  bool _isResetting = false;

  // Bandera para indicar si la duración se ha cargado
  bool _durationLoaded = false;

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
    _loadSelectedDuration();
  }

  Future<void> _loadSelectedDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDuration = prefs.getInt('selected_duration') ?? 25;
    if (mounted) {
      setState(() {
        _selectedDuration = savedDuration;
        _durationLoaded = true;

        // Si el servicio no está activo, asegurar que el remaining coincida con la duración seleccionada
        if (!_isServiceRunning) {
          _remaining = _selectedDuration * 60;
        }
      });
    }
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

    // Ignorar datos del background task si estamos en proceso de reset
    if (_isResetting) {
      print('🔄 Ignorando datos del background task durante reset');
      return;
    }

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
      }
    }
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSelectedDuration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_duration', _selectedDuration);
  }

  Future<void> _selectDuration(int duration) async {
    if (_selectedDuration == duration) return;

    // No permitir cambiar duración si el servicio está activo (corriendo o pausado)
    if (_isServiceRunning) {
      print('⚠️ No se puede cambiar duración mientras el servicio está activo');
      return;
    }

    print('⏰ Cambiando duración de $_selectedDuration a $duration minutos');

    setState(() {
      _selectedDuration = duration;
    });

    await _saveSelectedDuration();

    // Si el servicio está corriendo, detenerlo y reiniciar con la nueva duración
    if (_isServiceRunning) {
      print('🔄 Deteniendo servicio para cambiar duración...');
      await FlutterForegroundTask.stopService();

      // Esperar un poco para que el servicio se detenga completamente
      await Future.delayed(const Duration(milliseconds: 300));

      // Reiniciar con la nueva duración
      await _startServiceWithDuration(duration * 60);
    } else {
      // Si no está corriendo, solo actualizar el tiempo restante
      setState(() {
        _remaining = duration * 60;
      });
      widget.onStateChanged(_remaining, _isRunning, _isServiceRunning);
    }
  }

  Future<void> _startServiceWithDuration(int durationInSeconds) async {
    print(
      '🚀 Iniciando servicio con duración: ${durationInSeconds ~/ 60} minutos',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('remaining', durationInSeconds);
    await prefs.setBool('isRunning', true);

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: '🧠 StudyFlow - Pomodoro Activo',
      notificationText: '⏳ Restan: ${formatTime(durationInSeconds)}',
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
      print('✅ Servicio iniciado correctamente con nueva duración');
      // Enviar el estado inicial al background task
      FlutterForegroundTask.sendDataToTask({
        "action": "start",
        "remaining": durationInSeconds,
        "isRunning": true,
      });
      setState(() {
        _remaining = durationInSeconds;
        _isRunning = true;
        _isServiceRunning = true;
      });
      widget.onStateChanged(_remaining, _isRunning, _isServiceRunning);
    } else {
      print('❌ No se pudo iniciar el servicio');
      _updateState(_remaining, false, false);
    }
  }

  Future<void> _toggle() async {
    print(
      '🔄 Botón toggle presionado - Estado actual: ${_isRunning ? "Corriendo" : "Pausado"}, Servicio: ${_isServiceRunning ? "Activo" : "Inactivo"}',
    );

    if (!_isServiceRunning) {
      print('🚀 Iniciando servicio de background task...');
      await _startServiceWithDuration(_selectedDuration * 60);
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
    print(
      '🛑 Botón reset presionado - Estado actual: ${_isRunning ? "Corriendo" : "Pausado"}, Servicio: ${_isServiceRunning ? "Activo" : "Inactivo"}',
    );

    // Activar bandera de reset
    _isResetting = true;

    // Detener el servicio primero si está activo
    if (_isServiceRunning) {
      print('🔄 Enviando acción RESET al background task...');
      FlutterForegroundTask.sendDataToTask({"action": "reset"});

      // Esperar un poco para que el background task procese el reset
      await Future.delayed(const Duration(milliseconds: 300));

      print('🛑 Deteniendo servicio de background task...');
      await FlutterForegroundTask.stopService();
      print('✅ Servicio detenido correctamente');

      // Verificar que el servicio realmente se detuvo
      bool serviceStopped = false;
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        serviceStopped = !(await FlutterForegroundTask.isRunningService);
        if (serviceStopped) break;
      }

      if (!serviceStopped) {
        print(
          '⚠️ El servicio no se detuvo correctamente, forzando detención...',
        );
        await FlutterForegroundTask.stopService();
      }
    }

    // Actualizar SharedPreferences
    final newRemaining = _selectedDuration * 60;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('remaining', newRemaining);
    await prefs.setBool('isRunning', false);
    print('💾 Estado reseteado en SharedPreferences');

    // Actualizar la UI después de asegurar que el servicio está detenido
    if (!mounted) return;

    setState(() {
      _remaining = newRemaining;
      _isRunning = false;
      _isServiceRunning = false;
    });

    // Notificar el cambio de estado
    widget.onStateChanged(newRemaining, false, false);

    // Desactivar bandera de reset después de un pequeño delay
    await Future.delayed(const Duration(milliseconds: 500));
    _isResetting = false;

    print(
      '✅ UI reseteada a ${_selectedDuration}:00 - Estado: Pausado, Servicio: Inactivo',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcular el progreso solo si el servicio está activo y hay tiempo transcurrido
    double targetProgress = 0.0;
    if (_isServiceRunning && _remaining < (_selectedDuration * 60)) {
      targetProgress = 1.0 - (_remaining / (_selectedDuration * 60));
    }

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

          // Botones de selección de duración
          if (_durationLoaded)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              height: 100, // Aumentado para que se vea el texto correctamente
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children:
                      _availableDurations.map((duration) {
                        final isSelected = _selectedDuration == duration;
                        final isDisabled = _isServiceRunning;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: GestureDetector(
                            onTap:
                                isDisabled
                                    ? null
                                    : () => _selectDuration(duration),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.lightBlue
                                        : isDisabled
                                        ? Colors.grey.withOpacity(0.05)
                                        : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.lightBlue
                                          : isDisabled
                                          ? Colors.grey.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '${duration}min',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : isDisabled
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Circular Timer
          Column(
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
                ],
              ),
            ],
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
