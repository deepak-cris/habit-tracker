import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/habit.dart';
import '../../utils/habit_utils.dart'; // Import the calculation utility

class StrengthProgressCard extends StatelessWidget {
  final Habit habit;
  final DateTime fromDate;
  final DateTime toDate;

  const StrengthProgressCard({
    super.key,
    required this.habit,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = calculateStrengthProgressData(
      habit,
      fromDate,
      toDate,
    );
    final int totalDaysInRange = toDate.difference(fromDate).inDays + 1;

    // Determine interval for bottom titles to avoid clutter
    double bottomTitleInterval = (totalDaysInRange / 5).ceilToDouble();
    if (bottomTitleInterval < 1)
      bottomTitleInterval = 1; // Ensure interval is at least 1

    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Habit Strength Progress',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180, // Slightly taller for better axis visibility
              child:
                  spots.isEmpty ||
                          spots.length <
                              2 // Need at least 2 points to draw a line
                      ? const Center(
                        child: Text('Not enough data for this period.'),
                      )
                      : LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: 100, // Percentage scale
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: 25,
                            verticalInterval:
                                bottomTitleInterval, // Use calculated interval
                            getDrawingHorizontalLine:
                                (value) => const FlLine(
                                  color: Colors.grey,
                                  strokeWidth: 0.5,
                                ),
                            getDrawingVerticalLine:
                                (value) => const FlLine(
                                  color: Colors.grey,
                                  strokeWidth: 0.5,
                                ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval:
                                    bottomTitleInterval, // Use calculated interval
                                getTitlesWidget: (value, meta) {
                                  // value is the day index (0 to totalDaysInRange - 1)
                                  final dayIndex = value.toInt();
                                  if (dayIndex < 0 ||
                                      dayIndex >= totalDaysInRange)
                                    return const SizedBox.shrink();

                                  final date = fromDate.add(
                                    Duration(days: dayIndex),
                                  );
                                  // Show labels only at intervals or first/last point
                                  if (dayIndex == 0 ||
                                      dayIndex == totalDaysInRange - 1 ||
                                      dayIndex % bottomTitleInterval.toInt() ==
                                          0) {
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 8.0,
                                      child: Text(
                                        DateFormat('d/MMM').format(date),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 25,
                                getTitlesWidget: (value, meta) {
                                  if (value > 100)
                                    return const SizedBox.shrink();
                                  return Text(
                                    '${value.toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  );
                                },
                                reservedSize: 40,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: false,
                              color: Colors.teal,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.teal.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
