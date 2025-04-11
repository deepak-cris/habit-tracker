import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../utils/habit_utils.dart'; // Import the calculation utility

class HabitGraphCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap; // Callback for tapping the card
  final int daysToShow = 30; // How many days of history to show

  const HabitGraphCard({super.key, required this.habit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = calculateHabitGraphData(
      habit,
      daysToShow: daysToShow,
    );
    final today = DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: InkWell(
        // Make the card tappable
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                height: 110, // Reduced height for the chart container
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100, // Percentage scale
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval:
                          25, // Show lines at 0, 25, 50, 75, 100%
                      verticalInterval:
                          (daysToShow / 5)
                              .floorToDouble(), // Adjust grid lines based on days shown
                      getDrawingHorizontalLine: (value) {
                        return const FlLine(
                          color: Colors.grey,
                          strokeWidth: 0.5,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return const FlLine(
                          color: Colors.grey,
                          strokeWidth: 0.5,
                        );
                      },
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
                              (daysToShow / 5)
                                  .floorToDouble(), // Show ~5 date labels
                          getTitlesWidget: (value, meta) {
                            // Calculate the date corresponding to the x-value index
                            // Remember: x=0 is furthest back, x=daysToShow-1 is today
                            final dayIndex = daysToShow - 1 - value.toInt();
                            if (dayIndex < 0 || dayIndex >= daysToShow)
                              return const SizedBox.shrink(); // Avoid out of bounds

                            final date = today.subtract(
                              Duration(days: dayIndex),
                            );
                            // Show labels only at intervals
                            if (value.toInt() % (daysToShow / 5).floor() == 0 ||
                                value.toInt() == daysToShow - 1) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text(
                                  DateFormat(
                                    'd/MMM',
                                  ).format(date), // Format like 11/Apr
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
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
                          interval: 25, // Show 0, 25, 50, 75, 100
                          getTitlesWidget: (value, meta) {
                            if (value > 100)
                              return const SizedBox.shrink(); // Don't show titles above 100
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.left,
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
                        isCurved: false, // Use straight lines
                        color: Colors.teal, // Match theme color
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(
                          show: false,
                        ), // Hide dots on points
                        belowBarData: BarAreaData(
                          // Fill area below line
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
      ),
    );
  }
}
