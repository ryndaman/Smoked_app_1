// lib/screens/summary_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smoked_1/models/equivalent_item.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';
import 'package:smoked_1/services/local_storage_service.dart';
import 'package:smoked_1/widgets/achievements_section.dart';
import 'package:smoked_1/widgets/daily_line_chart.dart';
import 'package:smoked_1/widgets/hourly_line_chart.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final List<bool> _selectedChart = <bool>[true, false];

  IconData _getIconForIdentifier(String identifier) {
    switch (identifier) {
      case 'utensils':
        return FontAwesomeIcons.utensils;
      case 'coffee':
        return FontAwesomeIcons.mugSaucer;
      case 'ticket':
        return FontAwesomeIcons.ticketSimple;
      case 'burger':
        return FontAwesomeIcons.burger;
      case 'gasPump':
        return FontAwesomeIcons.gasPump;
      case 'shirt':
        return FontAwesomeIcons.shirt;
      case 'gamepad':
        return FontAwesomeIcons.gamepad;
      case 'headphones':
        return FontAwesomeIcons.headphones;
      case 'plane':
        return FontAwesomeIcons.plane;
      case 'mobileScreenButton':
        return FontAwesomeIcons.mobileScreenButton;
      case 'mobileScreen':
        return FontAwesomeIcons.mobileScreen;
      case 'motorcycle':
        return FontAwesomeIcons.motorcycle;
      case 'stone':
        return FontAwesomeIcons.gem;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  Future<void> _onShare() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Generating report...')),
    );

    try {
      final filePath = await _storageService.generateCsvReport();
      await SharePlus.instance.share(
        ShareParams(
          text: 'My Smoked App Report',
          files: [XFile(filePath)],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmokeDataProvider>(
      builder: (context, dataProvider, child) {
        if (dataProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Your Summary')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final settings = dataProvider.settings;
        final rate =
            dataProvider.exchangeRates[settings.preferredCurrency] ?? 1.0;

        final totalCostInBase = dataProvider.events
            .fold(0.0, (sum, event) => sum + event.pricePerStick);
        final totalCostInPreferredCurrency = totalCostInBase * rate;

        EquivalentItem equivalentItem = const EquivalentItem(
            name: 'small stones...', price: 0, iconIdentifier: 'stone');

        // FIXED: Corrected logic to find the highest-value item user can afford.
        if (dataProvider.equivalents.isNotEmpty) {
          equivalentItem = dataProvider.equivalents.lastWhere(
              (item) => totalCostInBase >= item.price,
              orElse: () => const EquivalentItem(
                  name: 'small stones...', price: 0, iconIdentifier: 'stone'));
        }

        final formatter = NumberFormat.currency(
          locale: 'id_ID',
          symbol: '${settings.preferredCurrency} ',
          decimalDigits: 0,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Summary'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: dataProvider.loadInitialData,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share Report',
                onPressed:
                    dataProvider.dataLoadingError != null ? null : _onShare,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (dataProvider.dataLoadingError != null)
                Card(
                  color: Colors.red[50],
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[700], size: 40),
                        const SizedBox(height: 12),
                        Text(
                          "Data Error",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dataProvider.dataLoadingError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          "You've smoked the equivalent of:",
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        FaIcon(
                          _getIconForIdentifier(equivalentItem.iconIdentifier),
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          equivalentItem.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "(${formatter.format(totalCostInPreferredCurrency)})",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Consumption Pattern",
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                    ),
                  ),
                  ToggleButtons(
                    isSelected: _selectedChart,
                    onPressed: (int index) {
                      setState(() {
                        for (int i = 0; i < _selectedChart.length; i++) {
                          _selectedChart[i] = i == index;
                        }
                      });
                    },
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Theme.of(context).colorScheme.primary,
                    selectedColor: Colors.white,
                    fillColor: Theme.of(context).colorScheme.primary,
                    color: Theme.of(context).colorScheme.primary,
                    constraints: const BoxConstraints(
                      minHeight: 32.0,
                      minWidth: 64.0,
                    ),
                    children: const [
                      Text('Daily'),
                      Text('Hourly'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 160,
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                child: _selectedChart[0]
                    ? DailyLineChart(events: dataProvider.events)
                    : const HourlyLineChart(),
              ),
              const SizedBox(height: 16),
              const AchievementsSection(),
              const SizedBox(height: 16),
              Card(
                color: Colors.brown[50],
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "\"The man who moves a mountain begins by carrying away small stones.\"\n\n- Confucius",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
