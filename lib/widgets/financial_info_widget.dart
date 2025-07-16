// lib/widgets/financial_info_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';

class FinancialInfo extends StatefulWidget {
  final NumberFormat formatter;

  const FinancialInfo({super.key, required this.formatter});

  @override
  State<FinancialInfo> createState() => _FinancialInfoState();
}

class _FinancialInfoState extends State<FinancialInfo> {
  // MODIFIED: Set a high initial page for the "infinite" loop effect
  final PageController _savedPageController = PageController(initialPage: 5000);
  final PageController _spentPageController = PageController(initialPage: 5000);
  int _savedPageIndex = 5000;
  int _spentPageIndex = 5000;
  final List<String> _periods = ['Today', 'Week', 'Month', 'All-Time'];

  @override
  void dispose() {
    _savedPageController.dispose();
    _spentPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmokeDataProvider>(
      builder: (context, dataProvider, child) {
        final exchangeRate = dataProvider.settings
                .exchangeRates[dataProvider.settings.preferredCurrency] ??
            1.0;

        // MODIFIED: The entire widget is now wrapped in a styled Container to create the frame
        return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withAlpha(50), // Darker background frame
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  "Overall Progress",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface, // Use a readable color on the frame
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Saved Card Section ---
                    Expanded(
                      child: Column(
                        children: [
                          Text("Saved",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 80, // Fixed height for the PageView
                            child: PageView.builder(
                              controller: _savedPageController,
                              itemCount:
                                  10000, // Use a large number for "infinite" scroll
                              onPageChanged: (index) {
                                setState(() {
                                  _savedPageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                // Use modulo to loop through the periods
                                final period =
                                    _periods[index % _periods.length];
                                final savedAmount =
                                    dataProvider.moneySavedByPeriod[period] ??
                                        0.0;
                                final avertedSticks = dataProvider
                                        .sticksAvertedByPeriod[period] ??
                                    0;
                                return _StatCard(
                                  formatter: widget.formatter,
                                  amount: savedAmount * exchangeRate,
                                  subtitle: '$avertedSticks smoke(s) averted',
                                  period: period,
                                  color: Colors.green[800]!,
                                );
                              },
                            ),
                          ),
                          _buildIndicator(_savedPageIndex % _periods.length),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // --- Spent Card Section ---
                    Expanded(
                      child: Column(
                        children: [
                          Text("Turned to smoke",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 80, // Fixed height for the PageView
                            child: PageView.builder(
                              controller: _spentPageController,
                              itemCount:
                                  10000, // Use a large number for "infinite" scroll
                              onPageChanged: (index) {
                                setState(() {
                                  _spentPageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                // Use modulo to loop through the periods
                                final period =
                                    _periods[index % _periods.length];
                                final spentAmount =
                                    dataProvider.moneySpentByPeriod[period] ??
                                        0.0;
                                final totalSticks =
                                    dataProvider.events.where((e) {
                                  if (period == 'All-Time') return true;
                                  final days = period == 'Today'
                                      ? 1
                                      : (period == 'Week' ? 7 : 30);
                                  return e.timestamp.isAfter(DateTime.now()
                                      .subtract(Duration(days: days)));
                                }).length;

                                return _StatCard(
                                  formatter: widget.formatter,
                                  amount: spentAmount * exchangeRate,
                                  subtitle: 'from $totalSticks cigarette(s)',
                                  period: period,
                                  color: Colors.red[800]!,
                                );
                              },
                            ),
                          ),
                          _buildIndicator(_spentPageIndex % _periods.length),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ));
      },
    );
  }

  Widget _buildIndicator(int currentIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_periods.length, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}

// Helper widget for the content of each card in the PageView
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.formatter,
    required this.amount,
    required this.subtitle,
    required this.period,
    required this.color,
  });

  final NumberFormat formatter;
  final double amount;
  final String subtitle;
  final String period;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withAlpha(25),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              period,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatter.format(amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
            Flexible(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: color.withAlpha(200)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
