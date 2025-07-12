import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smoked_1/models/smoke_event.dart';

// This is a dedicated, reusable widget for our line chart.
class DailyLineChart extends StatelessWidget {
  // It takes the list of events as a parameter.
  final List<SmokeEvent> events;

  const DailyLineChart({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      _buildChartData(context),
    );
  }

  // All the chart-building logic is now contained within this widget.
  LineChartData _buildChartData(BuildContext context) {
    final Map<int, int> dailyCounts = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < 7; i++) {
      dailyCounts[i] = 0;
    }

    for (var event in events) {
      final eventDay =
          DateTime(event.timestamp.year, event.timestamp.month, event.timestamp.day);
      final difference = today.difference(eventDay).inDays;
      if (difference >= 0 && difference < 7) {
        dailyCounts[difference] = (dailyCounts[difference] ?? 0) + 1;
      }
    }

    final List<FlSpot> spots = dailyCounts.entries.map((entry) {
      return FlSpot((6 - entry.key).toDouble(), entry.value.toDouble());
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
                spot.y.toInt().toString(),
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
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final day = today.subtract(Duration(days: 6 - value.toInt()));
              // FIXED: The constructor now correctly uses 'meta' and does not use 'axisSide'.
              return SideTitleWidget(
                meta: meta,
                space: 4,
                child: Text(DateFormat.E().format(day),
                    style: const TextStyle(fontSize: 10)),
              );
            },
            reservedSize: 28,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: (dailyCounts.values.isEmpty
              ? 5
              : dailyCounts.values.reduce(max).toDouble()) +
          3,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: Theme.of(context).colorScheme.secondary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }
}
