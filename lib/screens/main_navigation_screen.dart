import 'dart:async';
import 'package:flutter/material.dart';
import 'package:studyflow_app/screens/ia_screen.dart';
import 'package:studyflow_app/screens/tasks_screen.dart';
import 'package:studyflow_app/screens/home_screen.dart';
import 'package:studyflow_app/screens/notes_screen.dart';
import 'package:studyflow_app/screens/pomodoro_screen.dart';
import '../components/bottom_nav_bar.dart';
import 'package:animations/animations.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startTimer() async {
    if (_isRunning) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
        });
      }
    });

    setState(() {
      _isRunning = true;
    });
  }

  void _pauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 25 * 60;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isForward = _selectedIndex >= _previousIndex;

    final List<Widget> screens = [
      const HomeScreen(),
      const TasksScreen(),
      PomodoroScreen(
        secondsRemaining: _secondsRemaining,
        isRunning: _isRunning,
        onStart: _startTimer,
        onPause: _pauseTimer,
        onReset: _resetTimer,
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
        child: BottomNavBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _previousIndex = _selectedIndex;
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
