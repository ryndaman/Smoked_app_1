// lib/providers/smoke_data_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smoked_1/data/health_data.dart';
import 'package:smoked_1/models/equivalent_item.dart';
import 'package:smoked_1/models/health_milestone.dart';
import 'package:smoked_1/models/smoke_event.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/services/local_storage_service.dart';

class SmokeDataProvider with ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();
  Timer? _savingsTimer;

  // --- State Properties ---
  bool _isLoading = true;
  late UserSettings _settings;
  late List<SmokeEvent> _events;
  late List<EquivalentItem> _equivalents;
  late List<HealthMilestone> _healthMilestones;

  double _totalMoneySaved =
      0.0; // This remains for the real-time "All-Time" value
  Map<int, double> _baselineHourlyMap = {};
  String? dataLoadingError;

  // ADDED: New properties to hold time-based metrics
  Map<String, double> moneySpentByPeriod = {};
  Map<String, double> moneySavedByPeriod = {}; // ADDED
  Map<String, int> sticksAvertedByPeriod = {};

  // This will hold the value loaded from storage, to be used by the timer.
  double _moneySavedSinceLastCalculation = 0.0;

  // --- Getters ---
  bool get isLoading => _isLoading;
  UserSettings get settings => _settings;
  List<SmokeEvent> get events => _events;
  List<EquivalentItem> get equivalents => _equivalents;
  List<HealthMilestone> get healthMilestones => _healthMilestones;
  double get totalMoneySaved => _totalMoneySaved;
  Map<int, double> get baselineHourlyMap => _baselineHourlyMap;
  int get totalSticks => _events.length;

  // --- Constructor ---
  SmokeDataProvider() {
    loadInitialData().then((_) {
      _initializeSavingsTimer();
    });
  }

  @override
  void dispose() {
    _savingsTimer?.cancel();
    super.dispose();
  }

  // --- Data Loading and Manipulation ---
  Future<void> loadInitialData() async {
    _isLoading = true;
    dataLoadingError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _storageService.getSettings(),
        _storageService.getSmokeEvents(),
        _loadEquivalentsFromCsv(),
        _loadMoneySaved(),
      ]);

      _settings = results[0] as UserSettings;
      _events = results[1] as List<SmokeEvent>;
      _equivalents = results[2] as List<EquivalentItem>;
      _moneySavedSinceLastCalculation = results[3] as double;
      _totalMoneySaved = _moneySavedSinceLastCalculation;

      _healthMilestones = HealthData.milestones;

      if (dataLoadingError == null && _equivalents.isEmpty) {
        dataLoadingError =
            "Could not load equivalent items. The file might be empty.";
      }

      _calculateAllMetrics();
    } catch (e) {
      dataLoadingError = "An unexpected error occurred: ${e.toString()}";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logSmokeEvent() async {
    final newEvent = SmokeEvent(
      timestamp: DateTime.now(),
      pricePerStick: _settings.pricePerStickInBaseCurrency,
    );
    _events.add(newEvent);

    _totalMoneySaved -= _settings.pricePerStickInBaseCurrency;
    if (_totalMoneySaved < 0) _totalMoneySaved = 0;

    await _storageService.saveEvents(_events);
    await _saveMoneySaved();
    _calculateAllMetrics();
    notifyListeners();
  }

  Future<void> logManualEntry(DateTimeRange range, int packs) async {
    await _storageService.logManualEntry(range, packs, _settings);
    await loadInitialData();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    _settings = newSettings;
    await _storageService.saveSettings(newSettings);
    await loadInitialData();
    _savingsTimer?.cancel();
    _initializeSavingsTimer();
  }

  // --- Helper Methods ---

  void _initializeSavingsTimer() {
    if (_settings.baselineCigsPerDay <= 0) return;

    final double costPerDay =
        _settings.baselineCigsPerDay * _settings.pricePerStickInBaseCurrency;
    final double savingsRatePerSecond = costPerDay / (24 * 60 * 60);

    _savingsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _totalMoneySaved += savingsRatePerSecond;
      if (DateTime.now().second % 60 == 0) {
        _saveMoneySaved();
      }
      notifyListeners();
    });
  }

  Future<void> _saveMoneySaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('total_money_saved', _totalMoneySaved);
  }

  Future<double> _loadMoneySaved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('total_money_saved') ?? 0.0;
  }

  void _calculateAllMetrics() {
    final now = DateTime.now();
    final pricePerStick = _settings.pricePerStickInBaseCurrency;

    List<SmokeEvent> getEventsForPeriod(int days) {
      final cutoff = now.subtract(Duration(days: days));
      return _events.where((event) => event.timestamp.isAfter(cutoff)).toList();
    }

    final periods = {'Today': 1, 'Week': 7, 'Month': 30};
    periods.forEach((key, days) {
      final eventsInPeriod = getEventsForPeriod(days);
      final costInPeriod = eventsInPeriod.length * pricePerStick;
      moneySpentByPeriod[key] = costInPeriod;

      final baselineSticksInPeriod = _settings.baselineCigsPerDay * days;
      final avertedSticks = baselineSticksInPeriod - eventsInPeriod.length;
      sticksAvertedByPeriod[key] = avertedSticks > 0 ? avertedSticks : 0;

      // ADDED: Calculate money saved for the specific period
      final baselineCostInPeriod = baselineSticksInPeriod * pricePerStick;
      final savedInPeriod = baselineCostInPeriod - costInPeriod;
      moneySavedByPeriod[key] = savedInPeriod > 0 ? savedInPeriod : 0;
    });

    final allTimeCost = _events.length * pricePerStick;
    moneySpentByPeriod['All-Time'] = allTimeCost;
    moneySavedByPeriod['All-Time'] =
        _totalMoneySaved; // Use the real-time value for all-time

    if (_events.isNotEmpty) {
      final daysSinceStart = now.difference(_events.first.timestamp).inDays + 1;
      final allTimeBaselineSticks =
          _settings.baselineCigsPerDay * daysSinceStart;
      final allTimeAvertedSticks = allTimeBaselineSticks - _events.length;
      sticksAvertedByPeriod['All-Time'] =
          allTimeAvertedSticks > 0 ? allTimeAvertedSticks : 0;
    } else {
      sticksAvertedByPeriod['All-Time'] = 0;
    }

    _generateBaselineHourlyMap();
  }

  void _generateBaselineHourlyMap() {
    final Map<int, double> hourlyDistribution = {
      for (var i = 0; i < 24; i++) i: 0.0
    };
    if (_settings.baselineCigsPerDay <= 0) {
      _baselineHourlyMap = hourlyDistribution;
      return;
    }

    final selectedTimes = _settings.smokingTimes;
    final timeRanges = {
      'In the Morning': {7, 8, 9},
      'During Work Breaks': {10, 15},
      'After Meals': {8, 13, 19},
      'While Driving': {7, 8, 17, 18},
      'With Coffee/Alcohol': {9, 16, 20},
    };

    final coreWakingHours = {
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22
    };
    final lateNightHours = {22, 23, 0, 1};

    Set<int> highTrafficHours = {};
    for (var time in selectedTimes) {
      if (timeRanges.containsKey(time)) {
        highTrafficHours.addAll(timeRanges[time]!);
      }
    }

    Set<int> allWakingHours = Set.from(coreWakingHours);
    if (selectedTimes.contains('Late at Night')) {
      allWakingHours.addAll(lateNightHours);
    }

    // Ensure high traffic hours are within the waking hours
    highTrafficHours = highTrafficHours.intersection(allWakingHours);

    final otherWakingHours = allWakingHours.difference(highTrafficHours);

    final double highTrafficCigs = _settings.baselineCigsPerDay * 0.7;
    final double otherCigs = _settings.baselineCigsPerDay * 0.3;

    if (highTrafficHours.isNotEmpty) {
      final double cigsPerHighTrafficHour =
          highTrafficCigs / highTrafficHours.length;
      for (var hour in highTrafficHours) {
        hourlyDistribution[hour] =
            (hourlyDistribution[hour] ?? 0) + cigsPerHighTrafficHour;
      }
    }

    if (otherWakingHours.isNotEmpty) {
      final double cigsPerOtherHour = (highTrafficHours.isEmpty
              ? _settings.baselineCigsPerDay
              : otherCigs) /
          otherWakingHours.length;
      for (var hour in otherWakingHours) {
        hourlyDistribution[hour] =
            (hourlyDistribution[hour] ?? 0) + cigsPerOtherHour;
      }
    }

    _baselineHourlyMap = hourlyDistribution;
  }

  Future<List<EquivalentItem>> _loadEquivalentsFromCsv() async {
    try {
      final rawCsv = await rootBundle.loadString('assets/equivalents.csv');
      final List<List<dynamic>> csvTable =
          const CsvToListConverter(eol: '\n').convert(rawCsv).sublist(1);

      List<EquivalentItem> loadedEquivalents = [];
      for (var row in csvTable) {
        if (row.length > 2) {
          loadedEquivalents.add(
            EquivalentItem(
              name: row[0].toString(),
              price: int.tryParse(row[1].toString()) ?? 0,
              iconIdentifier: row[2].toString(),
            ),
          );
        }
      }
      return loadedEquivalents;
    } catch (e) {
      debugPrint("Error loading equivalents.csv: $e");
      dataLoadingError =
          "Failed to load 'equivalents.csv'. Please check the file and restart the app.";
      return [];
    }
  }
}
