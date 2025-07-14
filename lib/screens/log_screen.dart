// lib/screens/log_screen.dart
import 'package:smoked_1/models/smoke_event.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _buttonUpdateTimer; // Timer for the button

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    //Start a timer that rebuilds the state every second to update the button gradient
    _buttonUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonUpdateTimer?.cancel();
    super.dispose();
  }

  //Logic to determine the button's gradient based on time
  Gradient _getButtonGradient(
      BuildContext context, SmokeDataProvider dataProvider) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color hotColor = Colors.red.shade800;

    if (dataProvider.events.isEmpty) {
      return LinearGradient(colors: [primaryColor, primaryColor]);
    }

    final SmokeEvent lastEvent = dataProvider.events.last;
    final Duration timeSinceLastSmoke =
        DateTime.now().difference(lastEvent.timestamp);

    const int periodInMinutes = 7;
    const int fullCycleMinutes = periodInMinutes * 4; // 28 minutes total cycle

    if (timeSinceLastSmoke.inMinutes >= fullCycleMinutes) {
      return LinearGradient(colors: [primaryColor, primaryColor]);
    }

    // Calculate the interpolation factor (0.0 = hot, 1.0 = normal)
    double t = timeSinceLastSmoke.inMinutes / fullCycleMinutes;
    t = t.clamp(0.0, 1.0); // Ensure t is between 0 and 1

    // Use lerp to smoothly transition from hotColor to primaryColor
    final Color interpolatedColor = Color.lerp(hotColor, primaryColor, t)!;

    return LinearGradient(
      colors: [
        interpolatedColor,
        Color.lerp(interpolatedColor, Colors.black, 0.2)!
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  //Logic of a count-up timer 'since your last smoke'
  Widget _getButtonChild(SmokeDataProvider dataProvider) {
    if (dataProvider.events.isEmpty) {
      return const Text(
        "I Smoked\nOne",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    final SmokeEvent lastEvent = dataProvider.events.last;
    final Duration timeSinceLastSmoke =
        DateTime.now().difference(lastEvent.timestamp);

    // Format the duration into HH:MM:SS
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(timeSinceLastSmoke.inHours);
    final minutes = twoDigits(timeSinceLastSmoke.inMinutes.remainder(60));
    final seconds = twoDigits(timeSinceLastSmoke.inSeconds.remainder(60));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "$hours:$minutes:$seconds",
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "since last smoke",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmokeDataProvider>(
      builder: (context, dataProvider, child) {
        if (dataProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final rate = dataProvider.settings
                .exchangeRates[dataProvider.settings.preferredCurrency] ??
            1.0;
        final displayCost = dataProvider.totalCostInBase * rate;
        final formatter = NumberFormat.currency(
          locale: 'id_ID',
          symbol: '${dataProvider.settings.preferredCurrency} ',
          decimalDigits: 0,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Smoked'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                // FIXED: Call the method without passing the context.
                onPressed: () => _showSettingsDialog(dataProvider),
              ),
              Tooltip(
                message: 'Log Missed Packs',
                child: IconButton(
                  icon: const Icon(Icons.edit_calendar_outlined),
                  // FIXED: Call the method without passing the context.
                  onPressed: () => _showManualEntryDialog(dataProvider),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Total Money Turned to Smoke",
                      style: TextStyle(
                        fontSize: 22,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final sineValue =
                            sin(4 * pi * _animationController.value);
                        return Transform.translate(
                          offset: Offset(sineValue * 15, 0),
                          child: child,
                        );
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatter.format(displayCost),
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      "from ${dataProvider.totalSticks} sticks",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 48),
                    AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      decoration: BoxDecoration(
                        gradient: _getButtonGradient(context, dataProvider),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(102),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          _animationController.forward(from: 0.0);
                          await dataProvider.logSmokeEvent();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(60),
                        ),
                        child: _getButtonChild(dataProvider),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // FIXED: Method no longer takes BuildContext as a parameter.
  void _showSettingsDialog(SmokeDataProvider dataProvider) {
    final priceController = TextEditingController(
        text: dataProvider.settings.pricePerPack.toString());
    final cigsController = TextEditingController(
        text: dataProvider.settings.cigsPerPack.toString());
    String selectedCurrency = dataProvider.settings.preferredCurrency;

    showDialog(
      // It uses the State's own `context` property.
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: dataProvider.settings.exchangeRates.keys
                        .map((String currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedCurrency = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                          labelText: 'Price per Pack ($selectedCurrency)'),
                      keyboardType: TextInputType.number),
                  TextField(
                      controller: cigsController,
                      decoration: const InputDecoration(
                          labelText: 'Cigarettes per Pack'),
                      keyboardType: TextInputType.number),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                child: const Text('Save'),
                onPressed: () async {
                  final newPrice = int.tryParse(priceController.text) ??
                      dataProvider.settings.pricePerPack;
                  final newCigs = int.tryParse(cigsController.text) ??
                      dataProvider.settings.cigsPerPack;

                  final navigator = Navigator.of(dialogContext);

                  await dataProvider.updateSettings(UserSettings(
                    pricePerPack: newPrice,
                    cigsPerPack: newCigs,
                    preferredCurrency: selectedCurrency,
                  ));

                  navigator.pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // FIXED: Method no longer takes BuildContext as a parameter.
  void _showManualEntryDialog(SmokeDataProvider dataProvider) async {
    // The await call happens here. It uses the State's own `context`.
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    // This is the definitive pattern: check `mounted` right after an `await`.
    if (!mounted || dateRange == null) {
      return;
    }

    _showPacksDialog(dataProvider, dateRange);
  }

  void _showPacksDialog(
      SmokeDataProvider dataProvider, DateTimeRange dateRange) {
    final packsController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Manual Entry'),
        content: TextField(
            controller: packsController,
            decoration:
                const InputDecoration(labelText: 'Number of Packs Smoked'),
            keyboardType: TextInputType.number),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Log'),
            onPressed: () async {
              final packs = int.tryParse(packsController.text) ?? 0;
              final navigator = Navigator.of(dialogContext);

              if (packs > 0) {
                await dataProvider.logManualEntry(dateRange, packs);
              }

              navigator.pop();
            },
          ),
        ],
      ),
    );
  }
}
