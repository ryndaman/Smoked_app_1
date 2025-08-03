// lib/providers/smoke_data_provider.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:smoked_1/data/health_data.dart';
import 'package:smoked_1/models/equivalent_item.dart';
import 'package:smoked_1/models/health_milestone.dart';
import 'package:smoked_1/models/smoke_event.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/services/achievement_service.dart';
import 'package:smoked_1/services/local_storage_service.dart';

class SmokeDataProvider with ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();
  final AchievementService _achievementService = AchievementService();

  // --- State Properties ---
  bool _isLoading = true;
  late UserSettings _settings;
  late List<SmokeEvent> _events;
  late List<EquivalentItem> _equivalents;
  late List<HealthMilestone> _healthMilestones;
  String? dataLoadingError;

  // --- Exchange rate
  Map<String, double> _exchangeRates = const {};

  // --- V2 Savings State ---
  double dailyPotentialSavings = 0.0;
  double weeklyNetSavings = 0.0;
  double monthlyNetSavings = 0.0;
  late DateTime _lastRolloverTimestamp;

  // --- Achievement State ---
  Set<String> unlockedAchievementIds = {};

  // --- Derived State ---
  SmokeEvent? _latestSmokeEvent;
  int cigsSmokedToday = 0;

  // --- Getters ---
  bool get isLoading => _isLoading;
  UserSettings get settings => _settings;
  List<SmokeEvent> get events => _events;
  List<EquivalentItem> get equivalents => _equivalents;
  int get totalSticks => _events.length;
  List<HealthMilestone> get healthMilestones => _healthMilestones;
  SmokeEvent? get latestSmokeEvent => _latestSmokeEvent;
  Map<String, double> get exchangeRates => _exchangeRates;

  // --- getter to handle price conversion
  double get _pricePerStickInBaseCurrency {
    if (_settings.cigsPerPack <= 0) return 0.0;
    final priceInPreferredCurrency =
        _settings.pricePerPack / _settings.cigsPerPack;
    final rate = _exchangeRates[_settings.preferredCurrency] ?? 1.0;
    if (rate == 0) return 0.0;
    return priceInPreferredCurrency / rate;
  }

  SmokeDataProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    dataLoadingError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _storageService.getSettings(),
        _storageService.getSmokeEvents(),
        _loadEquivalentsFromCsv(),
        _storageService.getData(),
        _loadExchangeRatesFromCsv(),
      ]);

      _settings = results[0] as UserSettings;
      _events = results[1] as List<SmokeEvent>;
      _equivalents = results[2] as List<EquivalentItem>;
      final data = results[3] as Map<String, dynamic>;
      _exchangeRates = results[4] as Map<String, double>;

      weeklyNetSavings = data['weeklyNetSavings'] ?? 0.0;
      monthlyNetSavings = data['monthlyNetSavings'] ?? 0.0;
      _lastRolloverTimestamp = data['lastRolloverTimestamp'] ?? DateTime.now();
      unlockedAchievementIds = data['unlockedAchievementIds'] ?? {};
      _healthMilestones = HealthData.milestones;

      await _handleDailyRollover();
      _updateDerivedState();
      _checkAchievements();
    } catch (e) {
      dataLoadingError = "An unexpected error occurred: ${e.toString()}";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logSmokeEvent() async {
    final newEvent = SmokeEvent(
      timestamp: DateTime.now(),
      pricePerStick: _pricePerStickInBaseCurrency,
    );
    _events.add(newEvent);

    dailyPotentialSavings -= _pricePerStickInBaseCurrency;
    if (dailyPotentialSavings < 0) dailyPotentialSavings = 0;

    _updateDerivedState();
    _checkAchievements();
    await _storageService.saveEvents(_events);
    await _persistData();
    notifyListeners();
  }

  Future<void> updateDailyLimit(int newLimit) async {
    _settings = _settings.copyWith(dailyLimit: newLimit);
    await _storageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    _settings = newSettings;
    await _storageService.saveSettings(_settings);
    await loadInitialData();
  }

  void _updateDerivedState() {
    if (_events.isEmpty) {
      _latestSmokeEvent = null;
      cigsSmokedToday = 0;
    } else {
      final sortedEvents = List<SmokeEvent>.from(_events)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _latestSmokeEvent = sortedEvents.first;
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    cigsSmokedToday =
        _events.where((event) => event.timestamp.isAfter(startOfToday)).length;
  }

  Future<void> _handleDailyRollover() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastRolloverDay = DateTime(_lastRolloverTimestamp.year,
        _lastRolloverTimestamp.month, _lastRolloverTimestamp.day);

    if (today.isAfter(lastRolloverDay)) {
      final daysToProcess = today.difference(lastRolloverDay).inDays;

      for (var i = 0; i < daysToProcess; i++) {
        final day = lastRolloverDay.add(Duration(days: i));
        final startOfDay = DateTime(day.year, day.month, day.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final smokesOnThatDay = _events
            .where((e) =>
                e.timestamp.isAfter(startOfDay) &&
                e.timestamp.isBefore(endOfDay))
            .length;

        final netSavings = (_settings.historicalAverage - smokesOnThatDay) *
            _pricePerStickInBaseCurrency;

        if (day.weekday == DateTime.monday) weeklyNetSavings = 0;
        if (day.day == 1) monthlyNetSavings = 0;

        if (netSavings > 0) {
          weeklyNetSavings += netSavings;
          monthlyNetSavings += netSavings;
        }
      }
      _lastRolloverTimestamp = now;
    }

    final startOfToday = DateTime(now.year, now.month, now.day);
    final smokesTodayCount =
        _events.where((e) => e.timestamp.isAfter(startOfToday)).length;

    dailyPotentialSavings = (_settings.historicalAverage - smokesTodayCount) *
        _pricePerStickInBaseCurrency;

    if (dailyPotentialSavings < 0) dailyPotentialSavings = 0;

    await _persistData();
  }

  Future<void> _persistData() async {
    await _storageService.saveData(
      weeklyNetSavings: weeklyNetSavings,
      monthlyNetSavings: monthlyNetSavings,
      lastRolloverTimestamp: _lastRolloverTimestamp,
      unlockedAchievementIds: unlockedAchievementIds,
    );
  }

  Future<void> logManualEntry(DateTimeRange range, int packs) async {
    if (settings.cigsPerPack <= 0 || packs <= 0) return;

    final totalSticks = packs * settings.cigsPerPack;
    final pricePerStickInBase = _pricePerStickInBaseCurrency;
    final newEvents = <SmokeEvent>[];
    final random = Random();

    // Define a list of typical waking hours for more realistic distribution.
    const wakingHours = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];

    // 1. Distribute sticks evenly across the selected days.
    final startDay = DateTime(range.start.year, range.start.month, range.start.day);
    final endDay = DateTime(range.end.year, range.end.month, range.end.day);
    final numberOfDays = endDay.difference(startDay).inDays + 1;
    final sticksPerDay = totalSticks ~/ numberOfDays;
    int remainderSticks = totalSticks % numberOfDays;

    // 2. For each day, create events with randomized timestamps within waking hours.
    for (int i = 0; i < numberOfDays; i++) {
      final currentDay = startDay.add(Duration(days: i));
      int sticksForThisDay = sticksPerDay + (remainderSticks > 0 ? 1 : 0);
      if (remainderSticks > 0) remainderSticks--;

      for (int j = 0; j < sticksForThisDay; j++) {
        // 3. Modulate the output by picking a random hour and minute.
        final hour = wakingHours[random.nextInt(wakingHours.length)];
        final minute = random.nextInt(60);
        final timestamp = DateTime(currentDay.year, currentDay.month, currentDay.day, hour, minute);

        newEvents.add(
          SmokeEvent(
            timestamp: timestamp,
            pricePerStick: pricePerStickInBase,
          ),
        );
      }
    }

    // 4. Save the newly generated events and reload all data.
    _events.addAll(newEvents);
    await _storageService.saveEvents(_events);
    await loadInitialData();
  }

  void _checkAchievements() {
    final newAchievements = _achievementService.checkAchievements(
      dataProvider: this,
      previouslyUnlockedIds: unlockedAchievementIds,
    );
    if (newAchievements.isNotEmpty) {
      unlockedAchievementIds.addAll(newAchievements.map((ach) => ach.id));
    }
  }

  // Load and parse exchange rate from the asset CSV
  Future<Map<String, double>> _loadExchangeRatesFromCsv() async {
    try {
      final rawCsv = await rootBundle.loadString('assets/exchange_rates.csv');
      final List<List<dynamic>> csvTable =
          const CsvToListConverter(eol: '\n').convert(rawCsv);

      return {
        for (var row in csvTable)
          row[0].toString().trim(): double.tryParse(row[1].toString()) ?? 1.0,
      };
    } catch (e) {
      debugPrint("Error loading exchange_rates.csv: $e");
      dataLoadingError = "Failed to load 'exchange_rates.csv'.";
      return {'USD': 1.0, 'IDR': 16000.0};
    }
  }

  Future<List<EquivalentItem>> _loadEquivalentsFromCsv() async {
    try {
      final rawCsv = await rootBundle.loadString('assets/equivalents.csv');
      final List<List<dynamic>> csvTable =
          const CsvToListConverter(eol: '\n').convert(rawCsv).sublist(1);
      return csvTable
          .where((row) => row.length > 2)
          .map((row) => EquivalentItem(
                name: row[0].toString(),
                price: int.tryParse(row[1].toString()) ?? 0,
                iconIdentifier: row[2].toString().trim(),
              ))
          .toList();
    } catch (e) {
      debugPrint("Error loading equivalents.csv: $e");
      dataLoadingError = "Failed to load 'equivalents.csv'.";
      return [];
    }
  }
}
