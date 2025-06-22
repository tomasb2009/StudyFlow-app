import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/pomodoro_stats.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(PomodoroHandler());
}

class PomodoroHandler extends TaskHandler {
  int _remaining = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  bool _timerActive = false;
  int _lastTick = 0; // Para calcular segundos transcurridos
  PomodoroStats? _stats;
  int _selectedDuration = 25; // Nueva variable para la duración seleccionada

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print(
      '🚀 Background task iniciado - Timestamp: ${timestamp.toIso8601String()}',
    );

    final prefs = await SharedPreferences.getInstance();
    _remaining = prefs.getInt('remaining') ?? 25 * 60;
    _isRunning = prefs.getBool('isRunning') ?? false;
    _selectedDuration =
        prefs.getInt('selected_duration') ?? 25; // Cargar duración seleccionada

    // Cargar stats
    final statsJson = prefs.getString('pomodoro_stats');
    if (statsJson != null) {
      _stats = PomodoroStats.fromJson(statsJson);
    } else {
      _stats = PomodoroStats(dailySeconds: {});
    }
    _lastTick = _remaining;

    print(
      '📊 Estado inicial cargado - Remaining: $_remaining, Running: $_isRunning, Duration: ${_selectedDuration}min',
    );

    _updateNotification();
    _sendStateToUI();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Solo usamos onRepeatEvent para mantener el servicio vivo
    // No para el conteo del timer
    print('🔄 onRepeatEvent - Manteniendo servicio vivo');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _stopTimer();
    await _saveState();
    FlutterForegroundTask.sendDataToMain({
      'action': 'serviceStopped',
      'remaining': _remaining,
      'isRunning': false,
    });
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'pause_resume') {
      _isRunning = !_isRunning;
      _saveState();

      // Manejar el timer según el estado
      if (_isRunning) {
        if (!_timerActive) {
          _startTimer();
        }
      } else {
        _stopTimer();
      }
      // Enviar estado después de cambiar el timer
      _sendStateToUI();
    }
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      if (data['action'] == 'start') {
        // Iniciar el pomodoro con el estado recibido
        print(
          '🎯 Recibida acción START - Remaining: ${data['remaining']}, Running: ${data['isRunning']}',
        );
        _remaining = data['remaining'] ?? 25 * 60;
        _isRunning = data['isRunning'] ?? true;
        _selectedDuration =
            (_remaining / 60).round(); // Actualizar duración seleccionada
        print(
          '✅ Estado actualizado - Remaining: $_remaining, Running: $_isRunning, Duration: ${_selectedDuration}min',
        );
        _saveState();

        // Iniciar el timer solo si no está activo
        if (!_timerActive) {
          _startTimer();
          // Enviar estado inmediatamente después de iniciar el timer
          print('📤 Enviando confirmación de inicio a la UI');
          _sendStateToUI();
        }
      } else if (data['action'] == 'pause') {
        _isRunning = !_isRunning;
        _saveState();

        // Manejar el timer según el estado
        if (_isRunning) {
          if (!_timerActive) {
            _startTimer();
          }
        } else {
          _stopTimer();
        }
        // Enviar estado después de cambiar el timer
        _sendStateToUI();
      } else if (data['action'] == 'stop') {
        _stopTimer();
        FlutterForegroundTask.stopService();
      } else if (data['action'] == 'updateTime') {
        _remaining = data['remaining'];
        _selectedDuration =
            (_remaining / 60).round(); // Actualizar duración seleccionada
        _updateNotification();
        _sendStateToUI();
        _saveState();
      } else if (data['action'] == 'reset') {
        print(
          '🔄 Recibida acción RESET - Deteniendo timer y reseteando estado',
        );
        _stopTimer();

        // Usar la duración seleccionada actual sin cargar desde SharedPreferences
        // ya que ya la tenemos en memoria
        _remaining = _selectedDuration * 60;
        _isRunning = false;

        print(
          '✅ Estado reseteado en background task - Remaining: $_remaining, Running: $_isRunning, Duration: ${_selectedDuration}min',
        );
        _saveState();
        _sendStateToUI();
        _sendStatsToUI();
      } else if (data['action'] == 'getState') {
        _sendStateToUI();
      } else if (data['action'] == 'getStats') {
        _sendStatsToUI();
      } else if (data['action'] == 'changeDuration') {
        // Nueva acción para cambiar duración
        final newDuration = data['duration'] ?? 25;
        print('⏰ Cambiando duración a $newDuration minutos');
        _selectedDuration = newDuration;
        _remaining = _selectedDuration * 60;
        _isRunning = false;
        _saveState();
        _sendStateToUI();
      }
    }
  }

  void _updateNotification() {
    FlutterForegroundTask.updateService(
      notificationTitle:
          _isRunning
              ? '🧠 StudyFlow - Pomodoro Activo'
              : '⏸️ StudyFlow - En Pausa',
      notificationText: '⏳ Restan: ${_formatTime(_remaining)}',
      notificationButtons: [
        NotificationButton(
          id: 'pause_resume',
          text: _isRunning ? 'Pausar' : 'Reanudar',
        ),
      ],
    );
  }

  void _sendStateToUI() {
    // Actualizar la notificación automáticamente cuando se envía el estado
    _updateNotification();

    FlutterForegroundTask.sendDataToMain({
      'remaining': _remaining,
      'isRunning': _isRunning,
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('remaining', _remaining);
    await prefs.setBool('isRunning', _isRunning);
    await prefs.setInt(
      'selected_duration',
      _selectedDuration,
    ); // Guardar duración seleccionada
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    if (_timerActive) return;

    print('⏰ Iniciando timer interno');
    _timerActive = true;
    _lastTick = _remaining;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      if (_isRunning && _remaining > 0) {
        _remaining--;
        int elapsed = _lastTick - _remaining;
        if (elapsed > 0) {
          _stats?.addTodaySeconds(elapsed);
          await _saveStats();
          _sendStatsToUI();
        }
        _lastTick = _remaining;
        print('⏰ Decrementando tiempo - Nuevo remaining: $_remaining');
        _sendStateToUI();
        _saveState();
      } else if (_remaining == 0) {
        _isRunning = false;
        print('🏁 Pomodoro terminado - Deteniendo servicio');
        _sendStateToUI();
        _saveState();
        _stopTimer();
        FlutterForegroundTask.stopService();
      }
    });
  }

  void _stopTimer() {
    if (_timer != null) {
      print('⏹️ Deteniendo timer interno');
      _timer!.cancel();
      _timer = null;
      _timerActive = false;
    }
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (_stats != null) {
      await prefs.setString('pomodoro_stats', _stats!.toJson());
    }
  }

  void _sendStatsToUI() {
    if (_stats != null) {
      FlutterForegroundTask.sendDataToMain({
        'action': 'pomodoroStats',
        'stats': _stats!.toJson(),
      });
    }
  }
}
