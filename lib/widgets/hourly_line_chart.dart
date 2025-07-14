// lib/widgets/hourly_line_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smoked_1/models/smoke_event.dart';

class HourlyLineChart extends StatelessWidget {
  final List<SmokeEvent> events;

  const HourlyLineChart({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    // The main widget is now a Column to include the chart and the explanation text.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LineChart(
            _buildChartData(context),
          ),
        ),
        const SizedBox(height: 8),
        // ADDED: Explanation text below the chart.
        Text(
          "*Chart shows the daily average number of cigarettes smoked per 2-hour block over the last 7 days.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // MODIFIED: This entire method is refactored to group data into 2-hour bins.
  LineChartData _buildChartData(BuildContext context) {
    // 1. Initialize a map to hold the TOTAL count for each 2-hour bin.
    // There will be 12 bins, indexed 0 to 11.
    final Map<int, int> twoHourBinTotals = {for (var i = 0; i < 12; i++) i: 0};

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentEvents =
        events.where((event) => event.timestamp.isAfter(sevenDaysAgo)).toList();

    // 2. Populate the 2-hour bin totals.
    for (var event in recentEvents) {
      // Determine the bin index (0-11) for the event's hour.
      // e.g., hour 0 or 1 -> bin 0; hour 2 or 3 -> bin 1.
      final int binIndex = event.timestamp.hour ~/ 2;
      twoHourBinTotals[binIndex] = (twoHourBinTotals[binIndex] ?? 0) + 1;
    }

    // 3. Create the spots for the chart with the AVERAGE value for each bin.
    double maxAverage = 0;
    final List<FlSpot> spots = twoHourBinTotals.entries.map((entry) {
      final double average = entry.value / 7.0;
      if (average > maxAverage) {
        maxAverage = average;
      }
      // The x-value represents the start hour of the bin (0, 2, 4, ...).
      return FlSpot((entry.key * 2).toDouble(), average);
    }).toList();

    return LineChartData(
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) =>
              Theme.of(context).colorScheme.secondary,
          tooltipPadding: const EdgeInsets.all(8),
          tooltipMargin: 12,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                'Avg: ${spot.y.toStringAsFixed(1)}',
                TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              const FlLine(color: Colors.transparent),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Theme.of(context).colorScheme.secondary,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value % 1 != 0) {
                return Container();
              }
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              );
            },
            reservedSize: 28,
          ),
        ),
        // MODIFIED: Bottom titles now reflect the 2-hour bins.
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 4, // Show a label every 4 hours (every 2 bins).
            getTitlesWidget: (value, meta) {
              final hour = value.toInt();
              if (hour % 2 != 0 && hour != 0) {
                return Container();
              }
              final time = DateTime(2023, 1, 1, hour);
              final String timeText = DateFormat('ha').format(time);

              return SideTitleWidget(
                meta: meta,
                space: 4.0,
                child: Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
            reservedSize: 28,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 22, // The last data point is at hour 22.
      minY: 0,
      maxY: maxAverage == 0 ? 5 : (maxAverage.ceil() + 1).toDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: Theme.of(context).colorScheme.secondary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).colorScheme.secondary.withAlpha(77),
          ),
        ),
      ],
    );
  }
}
