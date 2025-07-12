import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smoked_1/models/smoke_event.dart';

class HourlyLineChart extends StatelessWidget {
  final List<SmokeEvent> events;

  const HourlyLineChart({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      _buildChartData(context),
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final Map<int, int> hourlyCounts = {};
    final now = DateTime.now();

    for (int i = 0; i < 24; i++) {
      hourlyCounts[i] = 0;
    }

    final todayEvents = events.where((event) {
      return event.timestamp.year == now.year &&
          event.timestamp.month == now.month &&
          event.timestamp.day == now.day;
    }).toList();

    for (var event in todayEvents) {
      hourlyCounts[event.timestamp.hour] =
          (hourlyCounts[event.timestamp.hour] ?? 0) + 1;
    }

    final List<FlSpot> spots = hourlyCounts.entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
    }).toList();

    return LineChartData(
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.secondary,
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
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
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
            interval: 6,
            getTitlesWidget: (value, meta) {
              String text;
              switch (value.toInt()) {
                case 0:
                  text = '00';
                  break;
                case 6:
                  text = '06';
                  break;
                case 12:
                  text = '12';
                  break;
                case 18:
                  text = '18';
                  break;
                default:
                  return Container();
              }
              return SideTitleWidget(
                meta: meta,
                space: 4,
                child: Text(text, style: const TextStyle(fontSize: 10)),
              );
            },
            reservedSize: 28,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 23,
      minY: 0,
      maxY: (hourlyCounts.values.isEmpty ? 5 : hourlyCounts.values.reduce(max).toDouble()) + 2,
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