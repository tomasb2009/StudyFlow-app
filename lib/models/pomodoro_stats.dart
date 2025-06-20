import 'dart:convert';

class PomodoroStats {
  /// Mapa de fecha (yyyy-MM-dd) a segundos acumulados de pomodoro
  final Map<String, int> dailySeconds;

  PomodoroStats({required this.dailySeconds});

  /// Devuelve un mapa solo con los últimos 7 días (incluyendo hoy)
  Map<String, int> getLast7Days() {
    final now = DateTime.now();
    final last7 = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = _dateKey(day);
      last7[key] = dailySeconds[key] ?? 0;
    }
    return last7;
  }

  /// Agrega segundos al día actual
  void addTodaySeconds(int seconds) {
    final key = _dateKey(DateTime.now());
    dailySeconds[key] = (dailySeconds[key] ?? 0) + seconds;
  }

  /// Serializa a JSON para guardar en SharedPreferences
  String toJson() => json.encode(dailySeconds);

  /// Crea desde JSON
  factory PomodoroStats.fromJson(String source) {
    final map = json.decode(source) as Map<String, dynamic>;
    return PomodoroStats(
      dailySeconds: map.map((k, v) => MapEntry(k, v as int)),
    );
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 