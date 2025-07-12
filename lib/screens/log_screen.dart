import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smoked_1/models/smoke_event.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/services/local_storage_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> with SingleTickerProviderStateMixin {
  final LocalStorageService _storageService = LocalStorageService();
  late UserSettings _settings;
  double _totalCostInBase = 0.0;
  int _totalSticks = 0;
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    final loadedSettings = await _storageService.getSettings();
    final List<SmokeEvent> loadedEvents = await _storageService.getSmokeEvents();
    double calculatedCost = 0.0;
    for (var event in loadedEvents) {
      calculatedCost += event.pricePerStick;
    }
    if (mounted) {
      setState(() {
        _settings = loadedSettings;
        _totalCostInBase = calculatedCost;
        _totalSticks = loadedEvents.length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rate = _isLoading ? 1.0 : _settings.exchangeRates[_settings.preferredCurrency] ?? 1.0;
    final displayCost = _totalCostInBase * rate;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: _isLoading ? "" : '${_settings.preferredCurrency} ',
      decimalDigits: 0,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smoked'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _isLoading ? null : _showSettingsDialog,
          ),
          Tooltip(
            message: 'Log Missed Packs',
            child: IconButton(
              icon: const Icon(Icons.edit_calendar_outlined),
              onPressed: _isLoading ? null : _showManualEntryDialog,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          final sineValue = sin(4 * pi * _animationController.value);
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
                        "from $_totalSticks sticks",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: () async {
                          _animationController.forward(from: 0.0);
                          await _storageService.logSmokeEvent();
                          _loadData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(60),
                          elevation: 8,
                          shadowColor: const Color.fromRGBO(0, 0, 0, 0.4),
                        ),
                        child: const Text(
                          "I Smoked\nOne",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _showSettingsDialog() {
    final priceController = TextEditingController(text: _settings.pricePerPack.toString());
    final cigsController = TextEditingController(text: _settings.cigsPerPack.toString());
    String selectedCurrency = _settings.preferredCurrency;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
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
                    items: _settings.exchangeRates.keys.map((String currency) {
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
                      decoration: InputDecoration(labelText: 'Price per Pack ($selectedCurrency)'),
                      keyboardType: TextInputType.number),
                  TextField(
                      controller: cigsController,
                      decoration: const InputDecoration(labelText: 'Cigarettes per Pack'),
                      keyboardType: TextInputType.number),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                child: const Text('Save'),
                onPressed: () async {
                  final newPrice = int.tryParse(priceController.text) ?? _settings.pricePerPack;
                  final newCigs = int.tryParse(cigsController.text) ?? _settings.cigsPerPack;
                  await _storageService.saveSettings(UserSettings(
                    pricePerPack: newPrice,
                    cigsPerPack: newCigs,
                    preferredCurrency: selectedCurrency,
                  ));
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  _loadData();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showManualEntryDialog() async {
    final packsController = TextEditingController();
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (dateRange == null) return;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Entry'),
        content: TextField(controller: packsController, decoration: const InputDecoration(labelText: 'Number of Packs Smoked'), keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Log'),
            onPressed: () async {
              final packs = int.tryParse(packsController.text) ?? 0;
              if (packs > 0) {
                await _storageService.logManualEntry(dateRange, packs, _settings);
              }
              if (!context.mounted) return;
              Navigator.of(context).pop();
              _loadData();
            },
          ),
        ],
      ),
    );
  }
}