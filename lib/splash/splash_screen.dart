import 'dart:async';
import 'package:flutter/material.dart';
import 'package:studyflow_app/screens/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double progress = 0.0;
  late Timer _timer;
  bool paused = false;

  @override
  void initState() {
    super.initState();
    simulateLoading();
  }

  void simulateLoading() {
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      setState(() {
        if (progress < 0.7) {
          progress += 0.02; // velocidad inicio
        } else if (!paused) {
          paused = true;
          _timer.cancel();
          // Pausa de 700ms al llegar al 70%
          Future.delayed(const Duration(milliseconds: 500), () {
            _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
              setState(() {
                progress += 0.05; // velocidad final
                if (progress >= 1.0) {
                  progress = 1.0;
                  timer.cancel();

                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const MainNavigationScreen(),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 200),
                    ),
                  );
                }
              });
            });
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "StudyFlow",
              style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 10,
              width: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 200 * progress,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
