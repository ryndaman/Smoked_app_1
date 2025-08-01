// lib/widgets/hourly_line_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';
import 'package:smoked_1/models/smoke_event.dart';

class HourlyLineChart extends StatelessWidget {
  const HourlyLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SmokeDataProvider>(
      builder: (context, dataProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LineChart(
                _buildChartData(context, dataProvider.events),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "*Chart shows your average hourly smoking pattern from the last 7 days.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      },
    );
  }

  LineChartData _buildChartData(
      BuildContext context, List<SmokeEvent> allEvents) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentEvents = allEvents.where((event) {
      return event.timestamp.isAfter(sevenDaysAgo);
    }).toList();

    //aggregate total cigarettes smoked for each hour
    final Map<int, int> hourlyTotals = {for (var i = 0; i < 24; i++) i: 0};
    for (final event in recentEvents) {
      final hour = event.timestamp.hour;
      hourlyTotals[hour] = (hourlyTotals[hour] ?? 0) + 1;
    }

    //Calculate the daily average for each hour
    final Map<int, double> hourlyAverages = {
      for (var i = 0; i < 24; i++) i: 0.0
    };
    hourlyTotals.forEach((hour, total) {
      hourlyAverages[hour] = total / 7;
    });

    //process the hourly averages into 2-hour bins
    final Map<int, double> twoHourBinTotals = {
      for (var i = 0; i < 12; i++) i: 0.0
    };

    hourlyAverages.forEach((hour, average) {
      final int binIndex = hour ~/ 2;
      twoHourBinTotals[binIndex] = (twoHourBinTotals[binIndex] ?? 0) + average;
    });

    //Convert binned data into FlSpot objects for the chart
    double maxAverage = 0;
    final List<FlSpot> spots = twoHourBinTotals.entries.map((entry) {
      final double average = entry.value;
      if (average > maxAverage) {
        maxAverage = average;
      }
      return FlSpot((entry.key * 2).toDouble(), average);
    }).toList();

    // Add a looping point to connect the end back to the start
    if (spots.isNotEmpty) {
      spots.add(FlSpot(24, spots.first.y));
    }

    // configure the final linechartdata for rendering
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
            showTitles: false,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value % 1 != 0 || value > maxAverage.ceil()) {
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
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 4,
            getTitlesWidget: (value, meta) {
              final hour = value.toInt();
              String timeText;
              if (hour == 24) {
                timeText = "12AM";
              } else {
                final time = DateTime(2023, 1, 1, hour);
                timeText = DateFormat('ha').format(time);
              }
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
      maxX: 24,
      minY: 0,
      maxY: maxAverage == 0 ? 1 : (maxAverage.ceil() + 1).toDouble(),
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
