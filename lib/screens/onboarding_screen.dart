// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/providers/theme_provider.dart';
import 'package:smoked_1/services/local_storage_service.dart';
import 'package:smoked_1/screens/home_page.dart';
import 'package:smoked_1/utils/app_themes.dart';
import 'package:smoked_1/utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _cigsController = TextEditingController();
  final UserSettings _tempSettings = UserSettings();
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = _tempSettings.preferredCurrency;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _cigsController.dispose();
    super.dispose();
  }

  void _saveAndContinue() async {
    final newPrice =
        int.tryParse(_priceController.text) ?? AppConstants.defaultPricePerPack;
    final newCigs =
        int.tryParse(_cigsController.text) ?? AppConstants.defaultCigsPerPack;

    await _storageService.saveSettings(UserSettings(
      pricePerPack: newPrice,
      cigsPerPack: newCigs,
      preferredCurrency: _selectedCurrency,
    ));

    await _storageService.setOnboarded();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Welcome to Smoked",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Let's get started by setting up your preferences.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),

                // ADDED: Theme Selection Section
                Text(
                  "Choose Your Theme",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ThemeSelectionChip(
                      theme: AppTheme.original,
                      label: "Original",
                      isSelected:
                          themeProvider.currentTheme == AppTheme.original,
                      onTap: () => themeProvider.setTheme(AppTheme.original),
                    ),
                    _ThemeSelectionChip(
                      theme: AppTheme.lightMonochrome,
                      label: "Mono",
                      isSelected: themeProvider.currentTheme ==
                          AppTheme.lightMonochrome,
                      onTap: () =>
                          themeProvider.setTheme(AppTheme.lightMonochrome),
                    ),
                    _ThemeSelectionChip(
                      theme: AppTheme.darkNeon,
                      label: "Neon",
                      isSelected:
                          themeProvider.currentTheme == AppTheme.darkNeon,
                      onTap: () => themeProvider.setTheme(AppTheme.darkNeon),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _tempSettings.exchangeRates.keys.map((String currency) {
                    return DropdownMenuItem<String>(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCurrency = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price per Pack ($_selectedCurrency)',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _cigsController,
                  decoration: const InputDecoration(
                    labelText: 'Cigarettes per Pack',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text(
                    'Save and Continue',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget for theme selection chips
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
