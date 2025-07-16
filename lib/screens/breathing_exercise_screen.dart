// lib/screens/breathing_exercise_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _instruction = "Get ready...";
  final List<String> _instructions = [
    "Breathe In",
    "Hold",
    "Breathe Out",
    "Hold"
  ];
  final List<Duration> _durations = [
    const Duration(seconds: 4),
    const Duration(seconds: 4),
    const Duration(seconds: 6),
    const Duration(seconds: 2),
  ];
  int _currentStep = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durations[0],
    );

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startExercise();
  }

  void _startExercise() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timer.tick == 1) {
        _runStep();
      }
    });
  }

  void _runStep() {
    if (!mounted) return;

    setState(() {
      _instruction = _instructions[_currentStep];
      _controller.duration = _durations[_currentStep];
    });

    if (_currentStep == 0) {
      // Breathe In
      _controller.forward();
    } else if (_currentStep == 2) {
      // Breathe Out
      _controller.reverse();
    }

    _timer = Timer(_durations[_currentStep], () {
      _currentStep = (_currentStep + 1) % _instructions.length;
      _runStep();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Take a Moment"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withAlpha(100),
                ),
              ),
            ),
            const SizedBox(height: 60),
            Text(
              _instruction,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
