// lib/screens/log_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';
import 'package:smoked_1/providers/theme_provider.dart';
import 'package:smoked_1/utils/app_themes.dart';
import 'package:smoked_1/widgets/financial_info_widget.dart';
import 'package:smoked_1/widgets/action_button_carousel.dart';
import 'package:smoked_1/widgets/since_last_smoke_timer.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  // REMOVED: The redundant timer is no longer needed here.
  // The SinceLastSmokeTimer widget now manages its own state and timer.

  @override
  Widget build(BuildContext context) {
    return Consumer<SmokeDataProvider>(
      builder: (context, dataProvider, child) {
        if (dataProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

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
                onPressed: () => _showSettingsDialog(dataProvider),
              ),
              Tooltip(
                message: 'Log Missed Packs',
                child: IconButton(
                  icon: const Icon(Icons.edit_calendar_outlined),
                  onPressed: () => _showManualEntryDialog(dataProvider),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FinancialInfo(formatter: formatter),
                    const SizedBox(height: 12),
                    const SinceLastSmokeTimer(),
                    const SizedBox(height: 12),
                    const ActionButtonCarousel(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSettingsDialog(SmokeDataProvider dataProvider) {
    final priceController = TextEditingController(
        text: dataProvider.settings.pricePerPack.toString());
    final cigsController = TextEditingController(
        text: dataProvider.settings.cigsPerPack.toString());
    final baselineCigsController = TextEditingController(
        text: dataProvider.settings.baselineCigsPerDay.toString());
    String selectedCurrency = dataProvider.settings.preferredCurrency;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "App Theme",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ThemeSelectionChip(
                        theme: AppTheme.original,
                        label: "Original",
                        isSelected:
                            themeProvider.currentTheme == AppTheme.original,
                        onTap: () {
                          themeProvider.setTheme(AppTheme.original);
                          setDialogState(() {});
                        },
                      ),
                      _ThemeSelectionChip(
                        theme: AppTheme.lightMonochrome,
                        label: "Mono",
                        isSelected: themeProvider.currentTheme ==
                            AppTheme.lightMonochrome,
                        onTap: () {
                          themeProvider.setTheme(AppTheme.lightMonochrome);
                          setDialogState(() {});
                        },
                      ),
                      _ThemeSelectionChip(
                        theme: AppTheme.darkNeon,
                        label: "Neon",
                        isSelected:
                            themeProvider.currentTheme == AppTheme.darkNeon,
                        onTap: () {
                          themeProvider.setTheme(AppTheme.darkNeon);
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 32),
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
                      controller: baselineCigsController,
                      decoration: const InputDecoration(
                          labelText: 'Avg. Cigarettes Per Day (Baseline)'),
                      keyboardType: TextInputType.number),
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
                  final newBaseline =
                      int.tryParse(baselineCigsController.text) ??
                          dataProvider.settings.baselineCigsPerDay;

                  final navigator = Navigator.of(dialogContext);

                  await dataProvider.updateSettings(UserSettings(
                    pricePerPack: newPrice,
                    cigsPerPack: newCigs,
                    preferredCurrency: selectedCurrency,
                    baselineCigsPerDay: newBaseline,
                    smokingTimes: dataProvider.settings.smokingTimes,
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

  void _showManualEntryDialog(SmokeDataProvider dataProvider) async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

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

class _ThemeSelectionChip extends StatelessWidget {
  final AppTheme theme;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeSelectionChip({
    required this.theme,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData;
    switch (theme) {
      case AppTheme.lightMonochrome:
        themeData = AppThemes.lightMonochrome;
        break;
      case AppTheme.darkNeon:
        themeData = AppThemes.darkNeon;
        break;
      default:
        themeData = AppThemes.original;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary, width: 3)
                  : null,
              gradient: LinearGradient(
                colors: [
                  themeData.colorScheme.primary,
                  themeData.scaffoldBackgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
