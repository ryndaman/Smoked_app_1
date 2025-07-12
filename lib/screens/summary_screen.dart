// --- Imports ---
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smoked_1/models/equivalent_item.dart';
import 'package:smoked_1/models/smoke_event.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/services/local_storage_service.dart';
import 'package:smoked_1/widgets/daily_line_chart.dart';
import 'package:smoked_1/widgets/hourly_line_chart.dart';

// --- Screen Widget ---
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

// --- Screen State ---
class _SummaryScreenState extends State<SummaryScreen> {
  // --- State Properties ---
  final LocalStorageService _storageService = LocalStorageService();
  bool _isLoading = true;
  late UserSettings _settings;
  late List<SmokeEvent> _events;
  late List<EquivalentItem> _equivalents;
  final List<bool> _selectedChart = <bool>[true, false];

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- Data Handling ---
  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final results = await Future.wait([
        _storageService.getSettings(),
        _storageService.getSmokeEvents(),
        rootBundle.loadString('assets/equivalents.csv'),
      ]);

      if (mounted) {
        setState(() {
          _settings = results[0] as UserSettings;
          _events = results[1] as List<SmokeEvent>;
          
          final rawCsv = results[2] as String;
          final List<List<dynamic>> csvTable =
              const CsvToListConverter().convert(rawCsv).sublist(1);

          _equivalents = [];
          for (var row in csvTable) {
            _equivalents.add(
              EquivalentItem(
                name: row[0].toString(),
                price: int.tryParse(row[1].toString()) ?? 0,
                iconIdentifier: row[2].toString(),
              ),
            );
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading summary data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Helper Methods ---
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


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // --- Local Calculation Variables ---
    EquivalentItem equivalentItem =
        const EquivalentItem(name: 'small stones...', price: 0, iconIdentifier: 'stone');
    double totalCostInPreferredCurrency = 0.0;
    
    if (!_isLoading) {
      double totalCostInBase = 0.0;
      for (var event in _events) {
        totalCostInBase += event.pricePerStick;
      }

      final rate = _settings.exchangeRates[_settings.preferredCurrency] ?? 1.0;
      totalCostInPreferredCurrency = totalCostInBase * rate;

      for (var item in _equivalents.reversed) {
        if (totalCostInPreferredCurrency >= item.price) {
          equivalentItem = item;
          break;
        }
      }
    }
    
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: _isLoading ? '' : '${_settings.preferredCurrency} ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Report',
            onPressed: _isLoading ? null : _onShare,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                // --- Equivalent Item Card ---
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

                // --- Chart Section ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // FIXED: Wrapped the Text widget in an Expanded widget to prevent overflow.
                    Expanded(
                      child: Text(
                        "Consumption Pattern",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      ? DailyLineChart(events: _events)
                      : HourlyLineChart(events: _events),
                ),
                const SizedBox(height: 16),

                // --- Quote Card ---
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
  }
}
