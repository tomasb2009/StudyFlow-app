import 'dart:async';
import 'package:flutter/material.dart';
import 'package:studyflow_app/screens/ia_screen.dart';
import 'package:studyflow_app/screens/tasks_screen.dart';
import 'package:studyflow_app/screens/home_screen.dart';
import 'package:studyflow_app/screens/notes_screen.dart';
import 'package:studyflow_app/screens/pomodoro_screen.dart';
import '../components/bottom_nav_bar.dart';
import 'package:animations/animations.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  int _previousIndex = 0;
  int _pomodoroRemaining = 25 * 60;
  bool _pomodoroIsRunning = false;
  bool _pomodoroServiceRunning = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializePomodoroState();
    FlutterForegroundTask.addTaskDataCallback(_onPomodoroData);
  }

  @override
  void dispose() {
    _timer?.cancel();
    FlutterForegroundTask.removeTaskDataCallback(_onPomodoroData);
    super.dispose();
  }

  Future<void> _initializePomodoroState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRemaining = prefs.getInt('remaining');
    final savedIsRunning = prefs.getBool('isRunning');
    final savedDuration = prefs.getInt('selected_duration') ?? 25;
    final isServiceRunning = await FlutterForegroundTask.isRunningService;

    if (!mounted) return;

    setState(() {
      _pomodoroServiceRunning = isServiceRunning;

      // Si el servicio está corriendo, usar el remaining guardado
      // Si no está corriendo, usar la duración seleccionada
      if (isServiceRunning && savedRemaining != null) {
        _pomodoroRemaining = savedRemaining;
        _pomodoroIsRunning = savedIsRunning ?? false;
      } else {
        // Servicio no activo, usar la duración seleccionada
        _pomodoroRemaining = savedDuration * 60;
        _pomodoroIsRunning = false;
      }
    });
  }

  void _onPomodoroData(Object data) {
    if (!mounted) return;

    if (data is Map) {
      if (data.containsKey("remaining")) {
        setState(() {
          _pomodoroRemaining = data["remaining"];
          _pomodoroIsRunning = data["isRunning"];
        });
      } else if (data.containsKey("action") &&
          data["action"] == "stateUpdate") {
        setState(() {
          _pomodoroRemaining = data["remaining"];
          _pomodoroIsRunning = data["isRunning"];
        });
      }
    }
  }

  void _onPomodoroStateChanged(
    int remaining,
    bool isRunning,
    bool serviceRunning,
  ) {
    setState(() {
      _pomodoroRemaining = remaining;
      _pomodoroIsRunning = isRunning;
      _pomodoroServiceRunning = serviceRunning;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isForward = _selectedIndex >= _previousIndex;

    final List<Widget> screens = [
      const HomeScreen(),
      const TasksScreen(),
      PomodoroScreen(
        initialRemaining: _pomodoroRemaining,
        initialIsRunning: _pomodoroIsRunning,
        initialServiceRunning: _pomodoroServiceRunning,
        onStateChanged: _onPomodoroStateChanged,
      ),
      const NotesScreen(),
      const IaScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 300),
          reverse: !isForward,
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return SharedAxisTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
          child: screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(currentIndex: _selectedIndex, onTap: _onItemTapped),
      ),
    );
  }
}
