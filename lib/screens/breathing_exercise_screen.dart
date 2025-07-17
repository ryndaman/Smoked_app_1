// lib/screens/breathing_exercise_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';

// Enum to manage the different states of the exercise.
enum _BreathingPhase { intro, countdown, inhale, hold, exhale }

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
  Timer? _timer;

  String _instructionText = "";
  String _countdownText = "";
  int _countdown = 3;

  // REVISED: Timings now follow the 4-7-8 method.
  final Map<_BreathingPhase, Duration> _durations = {
    _BreathingPhase.inhale: const Duration(seconds: 4),
    _BreathingPhase.hold: const Duration(seconds: 7),
    _BreathingPhase.exhale: const Duration(seconds: 8),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durations[_BreathingPhase.inhale],
    );
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _startIntro();
  }

  void _startIntro() {
    setState(() {
      _instructionText =
          "This is a 4-7-8 breathing exercise. Inhale for 4 seconds, hold for 7, and exhale for 8. We'll begin shortly.";
    });
    // MODIFIED: Increased intro time by 1 second for better user awareness.
    _timer = Timer(const Duration(seconds: 6), _startCountdown);
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _instructionText = "Get Ready...";
      _countdownText = _countdown.toString();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
          _countdownText = _countdown.toString();
        });
      } else {
        timer.cancel();
        _runStep(_BreathingPhase.inhale);
      }
    });
  }

  void _runStep(_BreathingPhase phase) {
    if (!mounted) return;

    setState(() {
      _countdownText = ""; // Clear countdown text
      _controller.duration = _durations[phase];

      switch (phase) {
        case _BreathingPhase.inhale:
          _instructionText = "Breathe In...";
          _controller.forward();
          break;
        case _BreathingPhase.hold:
          _instructionText = "Hold";
          break;
        case _BreathingPhase.exhale:
          _instructionText = "Breathe Out...";
          _controller.reverse();
          break;
        case _BreathingPhase.intro:
        case _BreathingPhase.countdown:
          break;
      }
    });

    _timer = Timer(_durations[phase]!, () {
      _BreathingPhase nextPhase;
      switch (phase) {
        case _BreathingPhase.inhale:
          nextPhase = _BreathingPhase.hold;
          break;
        case _BreathingPhase.hold:
          nextPhase = _BreathingPhase.exhale;
          break;
        case _BreathingPhase.exhale:
          nextPhase = _BreathingPhase.inhale; // Loop back
          break;
        case _BreathingPhase.intro:
        case _BreathingPhase.countdown:
          return;
      }
      _runStep(nextPhase);
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              // NOTE: .withAlpha() is the correct, non-deprecated method for this.
              Theme.of(context).colorScheme.primary.withAlpha(40),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // MODIFIED: Adjusted flex to move the circle up.
            Expanded(
              flex: 5, // Takes up 40% of the vertical space
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    _instructionText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 6, // Takes up 60% of the vertical space
              child: Center(
                child: ScaleTransition(
                  scale: _animation,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          Theme.of(context).colorScheme.primary.withAlpha(100),
                    ),
                    child: Center(
                      child: Text(
                        _countdownText,
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
