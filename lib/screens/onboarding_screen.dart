// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';
import 'package:smoked_1/services/local_storage_service.dart';
import 'package:smoked_1/screens/home_page.dart';
import 'package:smoked_1/utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Controllers for Stage 1
  final _baselineCigsController = TextEditingController();
  final _priceController = TextEditingController();
  final _cigsPerPackController = TextEditingController();
  String _selectedCurrency = AppConstants.defaultCurrency;

  // State for Stage 2
  final Set<String> _selectedTimes = {};
  final List<String> _timeOptions = [
    'In the Morning',
    'During Work Breaks',
    'After Meals',
    'While Driving',
    'With Coffee/Alcohol',
    'Late at Night',
  ];

  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _baselineCigsController.dispose();
    _priceController.dispose();
    _cigsPerPackController.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    // Final save operation
    final baselineValue = int.tryParse(_baselineCigsController.text) ??
        AppConstants.defaultCigsPerPack;
    final newPrice =
        int.tryParse(_priceController.text) ?? AppConstants.defaultPricePerPack;
    final newCigsPerPack = int.tryParse(_cigsPerPackController.text) ??
        AppConstants.defaultCigsPerPack;

    await _storageService.saveSettings(UserSettings(
      pricePerPack: newPrice,
      cigsPerPack: newCigsPerPack,
      preferredCurrency: _selectedCurrency,
      smokingTimes: _selectedTimes.toList(),
      historicalAverage: baselineValue,
    ));

    await _storageService.setOnboarded();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage == 0) {
      // Validate the form before proceeding from page 1
      if (_formKey.currentState!.validate()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // This is the final page
      _finishOnboarding();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // final dataProvider = Provider.of<SmokeDataProvider>(context, listen: false);
    return Scaffold(
      body: Consumer<SmokeDataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final currencyOptions = dataProvider.exchangeRates.keys.toList();

          if (!currencyOptions.contains(_selectedCurrency)) {
            _selectedCurrency =
                currencyOptions.isNotEmpty ? currencyOptions.first : 'USD';
          }

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  // MODIFIED: Wrapped PageView in a Stack to overlay arrows
                  child: Stack(
                    children: [
                      PageView(
                        controller: _pageController,
                        // MODIFIED: Swiping is now enabled by removing the physics property.
                        onPageChanged: (page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        children: [
                          _buildBaselinePage(currencyOptions),
                          _buildTriggersPage(),
                        ],
                      ),
                      // ADDED: Left arrow for navigation
                      if (_currentPage > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: _previousPage,
                            iconSize: 40,
                            color: Colors.grey.withAlpha(128),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildNavigationControls(),
              ],
            ),
          );
        },
      ),
    );
  }

  // STAGE 1: The Numbers
  Widget _buildBaselinePage(List<String> currencyOptions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Your Habit Baseline",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              "Let's quantify your current smoking habits to track your progress accurately.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _baselineCigsController,
              decoration: const InputDecoration(
                labelText: 'Avg. Cigarettes Per Day',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _cigsPerPackController,
              decoration: const InputDecoration(
                labelText: 'Cigarettes per Pack',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price per Pack',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: currencyOptions.map((String currency) {
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
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ADDED: Instructional text for clarity
            Text(
              "Swipe or use the buttons to navigate.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // STAGE 2: The Triggers
  Widget _buildTriggersPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Your Smoking Patterns",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            "Understanding when you smoke is the first step to changing the habit. Select all that apply.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: _timeOptions.map((time) {
              final isSelected = _selectedTimes.contains(time);
              return ChoiceChip(
                label: Text(time),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTimes.add(time);
                    } else {
                      _selectedTimes.remove(time);
                    }
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Navigation controls at the bottom
  Widget _buildNavigationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          if (_currentPage > 0)
            // MODIFIED: Added icon to button
            TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousPage,
              label: const Text('Back'),
            )
          else
            const SizedBox(width: 80), // Placeholder to keep layout consistent

          // Dots Indicator
          Row(
            children: List.generate(2, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                ),
              );
            }),
          ),

          // Next/Finish Button
          // MODIFIED: Added icon to button
          ElevatedButton.icon(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            label: Text(_currentPage == 1 ? 'Finish' : 'Next'),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
