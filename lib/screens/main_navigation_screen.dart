import 'package:flutter/material.dart';
import 'package:studyflow_app/screens/ia_screen.dart';
import 'package:studyflow_app/screens/tasks_screen.dart';
import 'package:studyflow_app/screens/home_screen.dart';
import 'package:studyflow_app/screens/notes_screen.dart';
import 'package:studyflow_app/screens/progress_screen.dart';
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

  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const ProgressScreen(),
    const NotesScreen(),
    const IaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isForward = _selectedIndex >= _previousIndex;

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
          child: _screens[_selectedIndex],
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
