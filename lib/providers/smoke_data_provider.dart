// lib/providers/smoke_data_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:smoked_1/data/health_data.dart';
import 'package:smoked_1/models/achievement.dart';
import 'package:smoked_1/models/equivalent_item.dart';
import 'package:smoked_1/models/health_milestone.dart';
import 'package:smoked_1/models/resisted_event.dart';
import 'package:smoked_1/models/smoke_event.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/services/achievement_service.dart';
import 'package:smoked_1/services/local_storage_service.dart';
import 'package:smoked_1/services/savings_service.dart';

class SmokeDataProvider with ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();
  final SavingsService _savingsService = SavingsService();
  final AchievementService _achievementService = AchievementService();
  Timer? _mainTimer;

  // --- State Properties ---
  bool _isLoading = true;
  late UserSettings _settings;
  late List<SmokeEvent> _events;
  late List<ResistedEvent> _resistedEvents;
  late List<EquivalentItem> _equivalents;
  late List<HealthMilestone> _healthMilestones;
  String? dataLoadingError;

  // --- V2 Savings & Averted Sticks State ---
  double dailySavings = 0.0;
  double weeklyNetSavings = 0.0;
  double monthlyNetSavings = 0.0;
  double dailyAvertedSticks = 0.0;
  int weeklyAvertedSticks = 0;
  int monthlyAvertedSticks = 0;
  late DateTime _lastRolloverTimestamp;
  Map<int, double> _baselineHourlyMap = {};

  // --- Achievement State ---
  Set<String> unlockedAchievementIds = {};
  List<Achievement> newlyUnlockedAchievements = [];

  // --- Getters ---
  bool get isLoading => _isLoading;
  UserSettings get settings => _settings;
  List<SmokeEvent> get events => _events;
  List<ResistedEvent> get resistedEvents => _resistedEvents;
  List<EquivalentItem> get equivalents => _equivalents;
  int get totalSticks => _events.length;
  Map<int, double> get baselineHourlyMap => _baselineHourlyMap;
  List<HealthMilestone> get healthMilestones => _healthMilestones;

  // --- Constructor & Dispose ---
  SmokeDataProvider() {
    loadInitialData();
  }

  @override
  void dispose() {
    _mainTimer?.cancel();
    super.dispose();
  }

  // --- Data Loading and Core Logic ---
  Future<void> loadInitialData() async {
    _isLoading = true;
    dataLoadingError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _storageService.getSettings(),
        _storageService.getSmokeEvents(),
        _storageService.getResistedEvents(),
        _loadEquivalentsFromCsv(),
        _storageService.getData(),
      ]);

      _settings = results[0] as UserSettings;
      _events = results[1] as List<SmokeEvent>;
      _resistedEvents = results[2] as List<ResistedEvent>;
      _equivalents = results[3] as List<EquivalentItem>;
      final data = results[4] as Map<String, dynamic>;

      dailySavings = data['dailySavings']!;
      weeklyNetSavings = data['weeklyNetSavings']!;
      monthlyNetSavings = data['monthlyNetSavings']!;
      dailyAvertedSticks = data['dailyAvertedSticks']!;
      weeklyAvertedSticks = data['weeklyAvertedSticks']!;
      monthlyAvertedSticks = data['monthlyAvertedSticks']!;
      _lastRolloverTimestamp = data['lastRolloverTimestamp']!;
      unlockedAchievementIds = data['unlockedAchievementIds']!;

      _healthMilestones = HealthData.milestones;
      _generateBaselineHourlyMap();

      await _handleDailyRollover();
      _initializeTimer();
      _checkAchievements();
    } catch (e) {
      dataLoadingError = "An unexpected error occurred: ${e.toString()}";
    }

    _isLoading = false;
    notifyListeners();
  }

  void _initializeTimer() {
    _mainTimer?.cancel();
    final savingsRate =
        _savingsService.calculateSavingsRatePerSecond(_settings);
    final avertedSticksRate = _settings.baselineCigsPerDay / (24 * 60 * 60);

    if (savingsRate <= 0 && avertedSticksRate <= 0) return;

    _mainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      dailySavings += savingsRate;
      dailyAvertedSticks += avertedSticksRate;
      _checkAchievements();

      if (DateTime.now().second % 15 == 0) {
        _persistData();
      }
      notifyListeners();
    });
  }

  // --- Event Logging ---
  Future<void> logSmokeEvent() async {
    final newEvent = SmokeEvent(
      timestamp: DateTime.now(),
      pricePerStick: _settings.pricePerStickInBaseCurrency,
    );
    _events.add(newEvent);

    dailySavings -= _settings.pricePerStickInBaseCurrency;
    if (dailySavings < 0) dailySavings = 0;

    dailyAvertedSticks -= 1;
    if (dailyAvertedSticks < 0) dailyAvertedSticks = 0;

    await _storageService.saveEvents(_events);
    _checkAchievements();
    await _persistData();
    notifyListeners();
  }

  Future<void> logResistedEvent() async {
    final newEvent = ResistedEvent(timestamp: DateTime.now());
    _resistedEvents.add(newEvent);
    await _storageService.saveResistedEvents(_resistedEvents);
    notifyListeners();
  }

  // FIXED: Re-added the logManualEntry method.
  Future<void> logManualEntry(DateTimeRange range, int packs) async {
    await _storageService.logManualEntry(range, packs, _settings);
    await loadInitialData(); // Reload all data to reflect the manual entry
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    _settings = newSettings;
    await _storageService.saveSettings(newSettings);
    await loadInitialData();
  }

  // --- Achievement Logic ---
  void _checkAchievements() {
    final newAchievements = _achievementService.checkAchievements(
      dataProvider: this,
      previouslyUnlockedIds: unlockedAchievementIds,
    );

    if (newAchievements.isNotEmpty) {
      for (final ach in newAchievements) {
        unlockedAchievementIds.add(ach.id);
      }
      newlyUnlockedAchievements.addAll(newAchievements);
    }
  }

  void clearNewlyUnlockedAchievements() {
    newlyUnlockedAchievements.clear();
    notifyListeners();
  }

  // --- Persistence and Rollover ---
  Future<void> _persistData() async {
    await _storageService.saveData(
      dailySavings: dailySavings,
      weeklyNetSavings: weeklyNetSavings,
      monthlyNetSavings: monthlyNetSavings,
      dailyAvertedSticks: dailyAvertedSticks,
      weeklyAvertedSticks: weeklyAvertedSticks,
      monthlyAvertedSticks: monthlyAvertedSticks,
      lastRolloverTimestamp: _lastRolloverTimestamp,
      unlockedAchievementIds: unlockedAchievementIds,
    );
  }

  Future<void> _handleDailyRollover() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastRolloverDay = DateTime(_lastRolloverTimestamp.year,
        _lastRolloverTimestamp.month, _lastRolloverTimestamp.day);

    if (today.isAfter(lastRolloverDay)) {
      final daysSinceLastRollover = today.difference(lastRolloverDay).inDays;

      for (var i = 0; i < daysSinceLastRollover; i++) {
        final dayToProcess = lastRolloverDay.add(Duration(days: i));

        double netSavingsForDay = (i == 0)
            ? dailySavings
            : _settings.baselineCigsPerDay *
                _settings.pricePerStickInBaseCurrency;
        int netAvertedSticksForDay = (i == 0)
            ? dailyAvertedSticks.floor()
            : _settings.baselineCigsPerDay;

        if (dayToProcess.weekday == DateTime.monday) {
          weeklyNetSavings = 0;
          weeklyAvertedSticks = 0;
        }
        if (dayToProcess.day == 1) {
          monthlyNetSavings = 0;
          monthlyAvertedSticks = 0;
        }

        weeklyNetSavings += netSavingsForDay;
        monthlyNetSavings += netSavingsForDay;
        weeklyAvertedSticks += netAvertedSticksForDay;
        monthlyAvertedSticks += netAvertedSticksForDay;
      }

      dailySavings = 0.0;
      dailyAvertedSticks = 0.0;
      _lastRolloverTimestamp = now;
      await _persistData();
    }
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
      21
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

      return csvTable
          .where((row) => row.length > 2)
          .map((row) => EquivalentItem(
                name: row[0].toString(),
                price: int.tryParse(row[1].toString()) ?? 0,
                iconIdentifier: row[2].toString(),
              ))
          .toList();
    } catch (e) {
      debugPrint("Error loading equivalents.csv: $e");
      dataLoadingError = "Failed to load 'equivalents.csv'.";
      return [];
    }
  }
}
