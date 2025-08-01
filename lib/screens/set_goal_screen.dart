// lib/screens/set_goal_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';

class SetLimitScreen extends StatefulWidget {
  const SetLimitScreen({super.key});

  @override
  State<SetLimitScreen> createState() => _SetLimitScreenState();
}

class _SetLimitScreenState extends State<SetLimitScreen> {
  late int _currentLimit;
  late int _originalLimit;

  @override
  void initState() {
    super.initState();
    final dataProvider = Provider.of<SmokeDataProvider>(context, listen: false);
    _originalLimit = dataProvider.settings.dailyLimit ??
        dataProvider.settings.historicalAverage;
    _currentLimit = _originalLimit;
  }

  void _updateLimit(int newLimit) {
    if (newLimit < 0) return; // Goal cannot be negative
    setState(() {
      _currentLimit = newLimit;
    });
  }

  void _saveLimit() {
    final dataProvider = Provider.of<SmokeDataProvider>(context, listen: false);
    dataProvider.updateDailyLimit(_currentLimit);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Your new limit has been set!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24.0,
          right: 24.0,
          top: 24.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.keyboard_arrow_down,
                size: 48, color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 20),
            Text(
              "What is your daily limit?",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "Adjust your daily cigarette limit. Lowering it over time is a great way to make progress.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  iconSize: 42,
                  onPressed: () => _updateLimit(_currentLimit - 1),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 24),
                Text(
                  _currentLimit.toString(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  iconSize: 42,
                  onPressed: () => _updateLimit(_currentLimit + 1),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            // REMOVED: The commitment bonus card is no longer needed.
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _currentLimit != _originalLimit ? _saveLimit : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text(
                'Save New Limit',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 80)
          ],
        ));
  }
}
