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
  static const int _initialPage = 3000;
  final PageController _savedPageController =
      PageController(initialPage: _initialPage);
  final PageController _spentPageController =
      PageController(initialPage: _initialPage);
  int _savedPageIndex = _initialPage;
  int _spentPageIndex = _initialPage;
  final List<String> _periods = ['Today', 'Last 7-days', 'Last 30-days'];
  final _compactFormatter = NumberFormat.compact();
  // final List<String> _periods = ['Today', 'This Week', 'This Month'];

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
        final exchangeRate = dataProvider
                .exchangeRates[dataProvider.settings.preferredCurrency] ??
            1.0;
// -- Variables --
        final savedAmounts = {
          'Today': dataProvider.dailyPotentialSavings,
          'Last 7-days': dataProvider.weeklyNetSavings,
          'Last 30-days': dataProvider.monthlyNetSavings,
        };

        return Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  "Financial Summary",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  // -- Saved Card & Wasted Card
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SAVED CARD SECTION ---
                    Expanded(
                      child: Column(
                        children: [
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("Money saved",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ))),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 90,
                            child: PageView.builder(
                              controller: _savedPageController,
                              itemCount: 10000,
                              onPageChanged: (index) =>
                                  setState(() => _savedPageIndex = index),
                              itemBuilder: (context, index) {
                                final period =
                                    _periods[index % _periods.length];
                                final subtitle = period == 'Today'
                                    ? 'Potential saving'
                                    : 'Net savings';
                                return _StatCard(
                                  formatter: widget.formatter,
                                  amount: (savedAmounts[period] ?? 0.0) *
                                      exchangeRate,
                                  subtitle: subtitle,
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
                    const SizedBox(width: 12),

                    // --- WASTED CARD SECTION ---
                    Expanded(
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text("Money turned to smoke",
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                )),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 90,
                            child: PageView.builder(
                              controller: _spentPageController,
                              itemCount: 10000,
                              onPageChanged: (index) =>
                                  setState(() => _spentPageIndex = index),
                              itemBuilder: (context, index) {
                                final period =
                                    _periods[index % _periods.length];
                                final eventsInPeriod =
                                    dataProvider.events.where((e) {
                                  final now = DateTime.now();
                                  if (period == 'Today') {
                                    return e.timestamp.year == now.year &&
                                        e.timestamp.month == now.month &&
                                        e.timestamp.day == now.day;
                                  }
                                  if (period == 'Last 7-days') {
                                    final sevenDaysAgo =
                                        now.subtract(const Duration(days: 7));
                                    return e.timestamp.isAfter(sevenDaysAgo);
                                  }
                                  if (period == 'Last 30-days') {
                                    final thirtyDaysAgo =
                                        now.subtract(const Duration(days: 30));
                                    return e.timestamp.isAfter(thirtyDaysAgo);
                                  }
                                  return false;
                                }).toList();

                                final spentAmount = eventsInPeriod.fold(0.0,
                                    (sum, event) => sum + event.pricePerStick);

                                return _StatCard(
                                  formatter: widget.formatter,
                                  amount: spentAmount * exchangeRate,
                                  subtitle:
                                      'from ${_compactFormatter.format(eventsInPeriod.length)} cigarette(s)',
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
    // -- simplify thousands
    String formattedAmount;
    if (amount > 9999999) {
      final thousands = amount / 1000;
      // Uses the locale from the original formatter to ensure correct separators.
      final thousandsFormatter = NumberFormat('#,##0', formatter.locale);
      formattedAmount =
          '${formatter.currencySymbol} ${thousandsFormatter.format(thousands)}K';
    } else {
      formattedAmount = formatter.format(amount);
    }

    // -- render statcard
    return Card(
      color: color.withAlpha(50),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(100), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              period,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Center(
                child: Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: color.withAlpha(255),
                    fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
