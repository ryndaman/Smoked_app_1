import 'package:flutter/material.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/services/local_storage_service.dart';
import 'package:smoked_1/screens/home_page.dart';

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
    final newPrice = int.tryParse(_priceController.text) ?? 35000;
    final newCigs = int.tryParse(_cigsController.text) ?? 16;
    await _storageService.saveSettings(UserSettings(
      pricePerPack: newPrice,
      cigsPerPack: newCigs,
      preferredCurrency: _selectedCurrency,
    ));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  "Let's get started by setting up the price of your cigarettes.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 48),
                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                  items: _tempSettings.exchangeRates.keys.map((String currency) {
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