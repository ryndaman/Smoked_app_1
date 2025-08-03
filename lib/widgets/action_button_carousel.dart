// lib/widgets/action_button_carousel.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      initialPage: 0,
      viewportFraction: 0.64,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
                Navigator.of(dialogContext).pop();
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
                Navigator.of(dialogContext).pop();
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
    return Consumer<SmokeDataProvider>(builder: (context, dataProvider, child) {
      final dailyGoal = dataProvider.settings.dailyLimit;
      final String counterText = dailyGoal != null
          ? "(${dataProvider.cigsSmokedToday}/$dailyGoal)"
          : "(Set Limit)";

      final List<Widget> actionButtons = [
        _ActionButton(
          // Action Button "I smoked one "
          label: "I smoked one",
          subtitle: dailyGoal != null ? "Your Limit:" : null,
          // Counter Customization
          counter: GestureDetector(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                counterText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: dailyGoal != null ? 22 : 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: dailyGoal != null
                      ? TextDecoration.none
                      : TextDecoration.none,
                  decorationColor: Colors.white70,
                  decorationThickness: 2,
                ),
              ),
            ),
          ),
          color: Colors.red,
          onPressed: () {
            dataProvider.logSmokeEvent();
          },
        ),
        _ActionButton(
          // Action Button "Ride the Wave"
          label: "Ride the Wave",
          subtitle: "This moment will pass",
          color: Colors.lightBlue,
          onPressed: () {
            _showCopingOptions(context);
          },
        ),
      ];

      return SizedBox(
        height: 200,
        child: PageView.builder(
          controller: _pageController,
          itemCount: actionButtons.length,
          itemBuilder: (context, index) {
            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = (_pageController.page! - index).abs();
                  value = (1 - (value * 0.4)).clamp(0.0, 1.0);
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
    });
  }
}

const double buttonElev = 50.0;
const int durationElev = 200; // Default duration for the button

class _ActionButton extends StatefulWidget {
  final String label;
  final String? subtitle;
  final Widget? counter;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    this.subtitle,
    this.counter,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: durationElev),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(begin: buttonElev, end: 0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    HapticFeedback.mediumImpact();
    _controller.forward().then((_) {
      widget.onPressed();
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    //Render the action button with animation
    return AnimatedBuilder(
      animation: _elevationAnimation,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
              width: 180,
              height: 180,
              child: ElevatedButton(
                onPressed: _handlePress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  elevation: _elevationAnimation.value,
                  shadowColor: widget.color.withAlpha(100),
                  animationDuration: Duration.zero,
                  padding: const EdgeInsets.all(20),
                ),
                child: child,
              )),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 0),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
          if (widget.counter != null) ...[
            const SizedBox(height: 0),
            // render counter widget --
            widget.counter!,
          ],
        ],
      ),
    );
  }
}
