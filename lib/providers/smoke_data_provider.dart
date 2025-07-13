// lib/providers/smoke_data_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:smoked_1/models/equivalent_item.dart';
import 'package:smoked_1/models/smoke_event.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/services/local_storage_service.dart';

class SmokeDataProvider with ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();

  // --- State Properties ---
  bool _isLoading = true;
  late UserSettings _settings;
  late List<SmokeEvent> _events;
  late List<EquivalentItem> _equivalents;
  double _totalCostInBase = 0.0;
  String? dataLoadingError; // ADDED: To hold any data loading errors.

  // --- Getters ---
  bool get isLoading => _isLoading;
  UserSettings get settings => _settings;
  List<SmokeEvent> get events => _events;
  List<EquivalentItem> get equivalents => _equivalents;
  double get totalCostInBase => _totalCostInBase;
  int get totalSticks => _events.length;

  // --- Constructor ---
  SmokeDataProvider() {
    loadInitialData();
  }

  // --- Data Loading and Manipulation ---
  Future<void> loadInitialData() async {
    _isLoading = true;
    dataLoadingError = null; // ADDED: Clear previous errors on reload.
    notifyListeners();

    try {
      final results = await Future.wait([
        _storageService.getSettings(),
        _storageService.getSmokeEvents(),
        _loadEquivalentsFromCsv(),
      ]);

      _settings = results[0] as UserSettings;
      _events = results[1] as List<SmokeEvent>;
      _equivalents = results[2] as List<EquivalentItem>;

      // If loading equivalents failed, the error will be set.
      if (dataLoadingError == null && _equivalents.isEmpty) {
        dataLoadingError =
            "Could not load equivalent items. The file might be empty.";
      }

      _calculateTotalCost();
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
    await _storageService.saveEvents(_events);
    _calculateTotalCost();
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
  }

  // --- Helper Methods ---
  void _calculateTotalCost() {
    _totalCostInBase =
        _events.fold(0.0, (sum, event) => sum + event.pricePerStick);
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
      // MODIFIED: Set the error message to be displayed in the UI.
      dataLoadingError =
          "Failed to load 'equivalents.csv'. Please check the file and restart the app.";
      return [];
    }
  }
}
