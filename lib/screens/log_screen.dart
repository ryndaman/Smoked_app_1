// lib/screens/log_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/models/achievement.dart';
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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dataProvider = Provider.of<SmokeDataProvider>(context);

    if (dataProvider.newlyUnlockedAchievements.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAchievementDialog(
              context, dataProvider.newlyUnlockedAchievements);
          dataProvider.clearNewlyUnlockedAchievements();
        }
      });
    }
  }

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

  // --- Dialogs ---

  void _showAchievementDialog(
      BuildContext context, List<Achievement> achievements) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(achievements.length > 1
              ? "Achievements Unlocked!"
              : "Achievement Unlocked!"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: achievements
                  .map((ach) => ListTile(
                        leading: FaIcon(
                            _getIconForIdentifier(ach.iconIdentifier),
                            color: Theme.of(context).colorScheme.primary),
                        title: Text(ach.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(ach.description),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Awesome!"),
            ),
          ],
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
                      // Updated Light Theme Chip
                      _ThemeSelectionChip(
                        theme: AppTheme.light,
                        label: "Light",
                        isSelected:
                            themeProvider.currentTheme == AppTheme.light,
                        onTap: () {
                          themeProvider.setTheme(AppTheme.light);
                          setDialogState(() {});
                        },
                      ),
                      // Updated Dark Theme Chip
                      _ThemeSelectionChip(
                        theme: AppTheme.dark,
                        label: "Dark",
                        isSelected: themeProvider.currentTheme == AppTheme.dark,
                        onTap: () {
                          themeProvider.setTheme(AppTheme.dark);
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

  IconData _getIconForIdentifier(String identifier) {
    switch (identifier) {
      case 'hourglass.start':
        return FontAwesomeIcons.hourglassStart;
      case 'calendar.week':
        return FontAwesomeIcons.calendarWeek;
      case 'shoe.prints':
        return FontAwesomeIcons.shoePrints;
      case 'list.ol':
        return FontAwesomeIcons.listOl;
      case 'mug.saucer':
        return FontAwesomeIcons.mugSaucer;
      case 'gamepad':
        return FontAwesomeIcons.gamepad;
      case 'sun':
        return FontAwesomeIcons.sun;
      case 'calendar.check':
        return FontAwesomeIcons.calendarCheck;
      case 'piggy.bank':
        return FontAwesomeIcons.piggyBank;
      default:
        // FIXED: Corrected deprecated icon name
        return FontAwesomeIcons.circleQuestion;
    }
  }
}

// FIXED: Re-added the _ThemeSelectionChip private widget
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
      case AppTheme.dark:
        themeData = AppThemes.darkTheme; // Use new darkTheme
        break;
      default:
        themeData = AppThemes.lightTheme; // Use new lightTheme as default
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
