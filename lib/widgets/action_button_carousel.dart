// lib/widgets/action_button_carousel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/data/coping_tips.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';
import 'package:smoked_1/screens/breathing_exercise_screen.dart';
import 'package:smoked_1/screens/coping_tip_screen.dart';
import 'dart:math';

class ActionButtonCarousel extends StatefulWidget {
  const ActionButtonCarousel({super.key});

  @override
  State<ActionButtonCarousel> createState() => _ActionButtonCarouselState();
}

class _ActionButtonCarouselState extends State<ActionButtonCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 1, // Start with the middle button
      viewportFraction: 0.6, // Show parts of adjacent pages
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // NEW: Method to show the coping options dialog.
  void _showCopingOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Ride the Wave"),
          content: const Text("How would you like to manage this craving?"),
          actions: [
            TextButton(
              child: const Text("Breathing Exercise"),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const BreathingExerciseScreen()),
                );
              },
            ),
            TextButton(
              child: const Text("Get a Quick Tip"),
              onPressed: () {
                final tip = CopingTipsData.getRandomTip();
                Navigator.of(dialogContext).pop(); // Close the dialog
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => CopingTipScreen(tip: tip)),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<SmokeDataProvider>(context, listen: false);

    final List<Widget> actionButtons = [
      _ActionButton(
        label: "I smoked one",
        color: Colors.red,
        onPressed: () {
          dataProvider.logSmokeEvent();
        },
      ),
      // --- Help Me Button ---
      _ActionButton(
        label: "Ride the Wave",
        subtitle: Text("this will pass", style: TextStyle(fontSize: 12.0)),
        color: Colors.lightBlue,
        onPressed: () {
          _showCopingOptions(context); // MODIFIED: Show dialog on press
        },
      ),
    ];

    return SizedBox(
      height: 200, // Provide a fixed height for the carousel
      child: PageView.builder(
        controller: _pageController,
        itemCount: actionButtons.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - (value.abs() * 0.4)).clamp(0.0, 1.0);
              }
              return Center(
                child: Opacity(
                  opacity: pow(value, 2).toDouble(),
                  child: Transform.scale(
                    scale: value,
                    child: child,
                  ),
                ),
              );
            },
            child: actionButtons[index],
          );
        },
      ),
    );
  }
}

// Helper widget for the individual circular buttons
class _ActionButton extends StatelessWidget {
  final String label;
  final Text? subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 180,
        height: 180,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            elevation: 8,
            shadowColor: color.withAlpha(100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                subtitle!,
              ],
            ],
          ),
        ));
  }
}
